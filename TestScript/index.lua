local im = require("imgui")
local ubviews = require("utilitybelt.views")
local acc = require("acclient")
local imgui = im.ImGui
local version = "1.0.0"

local gambling_max_tokens = 100
local dropItems = {}
dropItems["Golden Gromnie"] = 0
dropItems["Chocolate Gromnie"] = 0
dropItems["Candy Corn"] = 0
dropItems["Licorice Rat"] = 30
dropItems["Ivory Gromnie Wings"] = 0
dropItems["Pack Scarecrow"] = 0
dropItems["Black Luster Pearl"] = 0
dropItems["Renegade Herbal Kit"] = 5
dropItems["Greater Mana Kit"] = 5
dropItems["Greater Stamina Kit"] = 5
dropItems["Massive Mana Charge"] = 10
dropItems["Mana Forge Key"] = 0
dropItems["Sleech"] = 0
dropItems["Skeleton"] = 0
dropItems["Auroch"] = 0
dropItems["Lugian"] = 0
dropItems["Moar"] = 0
dropItems["The Orphanage"] = 0
local lootingColosseumVault = false
local lootColosseumVault = false
local turningInColoRings = false
local hudPosition = nil

function TryApplyIvoryToRings()
    local RingToUse = nil
    local IvoryToUse = nil
    print("Ivory: looking for rings")
    for _, object in ipairs(game.Character.Inventory) do
        if string.find(object.Name,"Empyrean Ring") then
            if not object.HasAppraisalData then
                await(game.Actions.ObjectAppraise(object.Id))
            end
            if object.HasAppraisalData
                and object.IntValues[IntId.Attuned] == 1 then
                    print("found: "..object.Name)
                    RingToUse = object
                    break
            end
        end
    end
    print("Ivory: looking for salvage")
    for _, object in ipairs(game.Character.Inventory) do
        if string.find(object.Name,"Salvage") 
            and object.IntValues[IntId.MaterialType] == MaterialType.Ivory 
            and object.IntValues[IntId.Structure] == 100 then
                print("found: "..object.Name)
                IvoryToUse = object
                break
        end
    end
    if IvoryToUse == nil then
        print("Ivory: No Ivory Bags")
        return false
    end
    if RingToUse == nil then
        print("Ivory: No Empyrean Rings")
        return false
    end
    await(game.Actions.ObjectUse(IvoryToUse.Id, RingToUse.Id))
    return true
end

function LootColosseumVault()
    -- Exit Combat Mode
    if game.Character.CombatMode ~= CombatMode.NonCombat then
        print("Vault: Exiting Combat Mode")
        await(game.Actions.SetCombatMode(CombatMode.NonCombat))
        sleep(750)
        lootingColosseumVault = false
        return
    end

    -- Make Sure We're In Range
    local vault = game.World.GetNearest("Colosseum Vault")
    if vault == nil or vault.DistanceTo2D(game.Character.Weenie) > 5 then
        lootingColosseumVault = false
        lootColosseumVault = false
        print("Vault: Not Found or Too Far Away")
        return
    end

    -- Check Lock Status
    print("Vault: Appraising")
    await(game.Actions.ObjectAppraise(vault.Id))
    sleep(100)
    local locked = vault.BoolValues[BoolId.Locked]

    -- Check If Opened
    local open = false
    if game.World.OpenContainer ~= nil then
        open = vault.Id == game.World.OpenContainer.Id
    end

    -- Display Locked/Open Status
    local lockedstring = "unlocked"
    local openstring = "closed"
    if locked then
        lockedstring = "locked"
    end
    if open then
        openstring = "open"
    end
    print("Vault: Lock Status = "..lockedstring)
    print("Vault: Open Status = "..openstring)

    local key = game.Character.GetFirstInventory("Colosseum Vault Key")
    -- If it's Locked + Not Open + No Key then We're Done
    if locked and not open and key == nil then
        print("Vault: Locked + Closed + No Key")
        lootColosseumVault = false
        lootingColosseumVault = false
        return
    end

    -- If it's Open, Look for Ring
    local ring = nil
    if open then
        for _, item in ipairs(game.World.OpenContainer.AllItems) do
            if string.find(item.Name,"Empyrean Ring") then
                ring = item
                break
            end
        end
        if ring ~= nil then
            print("Vault: Looting "..ring.Name)
            game.Actions.ObjectUse(ring.Id,0)
            sleep(750)
            lootingColosseumVault = false
            return
        else
            print("Vault: Closing")
            --game.Actions.ObjectUse(vault.Id,0)
            await(game.Actions.InvokeChat("/ub mexec actiontryuseitem[wobjectgetopencontainer[]]"))
            sleep(250)
            lootingColosseumVault = false
            return
        end
    end

    -- If it's Locked but we have a Key, lets Unlock it
    if locked and key ~= nil then
        print("Vault: Unlocking")
        await(game.Actions.ObjectUse(key.Id,vault.Id))
        sleep(250)
        lootingColosseumVault = false
        return
    end

    -- If it's Unlocked but Closed, let's Open it
    if not locked and not open then
        print("Vault: Opening")
        await(game.Actions.ObjectUse(vault.Id,0))
        sleep(250)
        lootingColosseumVault = false
        return
    end

    lootingColosseumVault = false
    return
end

function MakePyrealNuggets()
    local wrappedSlivers = {}
    local unwrappedSlivers = {}
    for _, action in ipairs(game.ActionQueue.Queue) do
       game.ActionQueue.Remove(action)
    end
    for _, item in ipairs(game.Character.Inventory) do
        if item.Name == "Wrapped Pyreal Sliver" then
            table.insert(wrappedSlivers,item)
        end
        if item.Name == "Pyreal Sliver" then
            table.insert(unwrappedSlivers,item)
        end
    end
    print("# of Wrapped Slivers = "..#wrappedSlivers)
    print("# of Unwrapped Slivers = "..#unwrappedSlivers)
    if #unwrappedSlivers >= 2 then
        await(game.Actions.ObjectUse(unwrappedSlivers[1].Id,unwrappedSlivers[2].Id))
    end
    if #wrappedSlivers > 0 then
        await(game.Actions.ObjectUse(wrappedSlivers[1].Id,0))
    end
end

function TurnInColoRings()
    local arbitrator = game.World.GetNearest("Master Arbitrator",DistanceType.T2D)
    local inventory = game.Character.Inventory
    local ring = nil
    for _, item in ipairs(inventory) do
        if string.find(item.Name,"Empyrean Ring") then
            ring = item
            break
        end
    end
    if ring == nil then
        turningInColoRings = false
        return
    end
    game.Actions.InvokeChat("/ub prepclick yes 10")
    game.Actions.ObjectGive(ring.Id,arbitrator.Id)
end

function SlideAway()
    local slidetime = 1200
    game.World.OnTick.Once(function()
        --game.Actions.InvokeChat("/ub bc /vtns")
        game.Actions.InvokeChat("/ub bc /vt opt set enablecombat false")
        game.Actions.InvokeChat("/ub bc /ub mexec clearmotion[]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[Backward,1]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[StrafeLeft,1]")
        sleep(slidetime) -- Custom Wait
        game.Actions.InvokeChat("/ub bc /ub mexec clearmotion[]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[Backward,1]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[StrafeLeft,0]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[StrafeRight,1]")
        sleep(slidetime) -- Custom Wait
        game.Actions.InvokeChat("/ub bc /ub mexec clearmotion[]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[Backward,1]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[StrafeLeft,1]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[StrafeRight,0]")
        sleep(slidetime) -- Custom Wait
        game.Actions.InvokeChat("/ub bc /ub mexec clearmotion[]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[Backward,1]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[StrafeLeft,0]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[StrafeRight,1]")
        sleep(slidetime) -- Custom Wait
        game.Actions.InvokeChat("/ub bc /ub mexec clearmotion[]")
        game.Actions.InvokeChat("/ub bc /vt opt set enablecombat true")
        --game.Actions.InvokeChat("/ub bc /ub follow Porkchop")
    end)
end

function SlideDirection(dir)
    local slidetime = 2500
    local slidecommand = ""
    if dir == 0 then
        slidecommand = "/ub bc /ub mexec setmotion[StrafeLeft,1]"
    else
        slidecommand = "/ub bc /ub mexec setmotion[StrafeRight,1]"
    end
    game.World.OnTick.Once(function()
        game.Actions.InvokeChat("/ub bc /vtns")
        game.Actions.InvokeChat("/ub bc /vt opt set enablecombat false")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[Backward,1]")
        game.Actions.InvokeChat(slidecommand)
        sleep(slidetime) -- Custom Wait
        game.Actions.InvokeChat("/ub bc /ub mexec clearmotion[]")
        game.Actions.InvokeChat("/ub bc /vt opt set enablecombat true")
        game.Actions.InvokeChat("/ub bc /ub follow Porkchop")
    end)
end

local hud = ubviews.Huds.CreateHud("TestScript v" .. version)
hud.ShowInBar = true
hud.WindowSettings = im.ImGuiWindowFlags.AlwaysAutoResize

-- Main HUD Render
hud.OnRender.Add(function ()
    if imgui.BeginTabBar("Main Tab") then

        -- Colo Helper Tab
        if imgui.BeginTabItem("Colo Helper") then

            if imgui.Button("Print + Clear Queue") then
                for _, value in ipairs(game.ActionQueue.Queue) do
                    print(value.Name..": "..value.CurrentRetryCount)
                    game.ActionQueue.Remove(value)
                end
                print("Actions Printed and Cleared")
            end

            if imgui.Button("Create Colo Key") then
                game.Actions.InvokeChat("/ci 34448")
            end

            if imgui.Button("Loot Colosseum Vault") then
                game.World.OnTick.Once(function()
                    lootColosseumVault = true
                    game.Actions.InvokeChat("/vt stop")
                    while lootColosseumVault do
                        if not lootingColosseumVault then
                            lootingColosseumVault = true
                            LootColosseumVault()
                            print("----------------------------------")
                        else
                            print("Vault: already looting")
                        end
                        sleep(100)
                    end
                    local applyingIvoryToRings = true
                    while applyingIvoryToRings do
                        applyingIvoryToRings = TryApplyIvoryToRings()
                        sleep(750)
                    end
                    game.Actions.InvokeChat("/vt start")
                end)
            end

            if imgui.Button("Add Ivory to Rings") then
                game.World.OnTick.Once(function()
                    local applyingIvoryToRings = true
                    while applyingIvoryToRings do
                        applyingIvoryToRings = TryApplyIvoryToRings()
                        sleep(750)
                    end
                end)
            end

            if imgui.Button("Turn in Colo Rings") then
                game.World.OnTick.Once(function()
                    turningInColoRings = true
                    while turningInColoRings do
                        game.Actions.InvokeChat("/vt stop")
                        TurnInColoRings()
                        sleep(1000)
                    end
                    game.Actions.InvokeChat("/vt start")
                end)
            end

            if imgui.Button("Dump All Excess Salvage") then
                game.Actions.InvokeChat("/ub bc /ub givep Ivory Salvage to Garbage Barrel")
            end

            if imgui.Button("Make Pyreal Nuggets") then
                game.World.OnTick.Once(function()
                    local makeNuggets = true
                    while makeNuggets do
                        game.Actions.InvokeChat("/vt stop")
                        MakePyrealNuggets()
                        sleep(250) -- Custom Wait
                        makeNuggets = game.Character.GetInventoryCount("Wrapped Pyreal Sliver") > 0 or game.Character.GetInventoryCount("Pyreal Sliver") > 0
                    end
                    game.Actions.InvokeChat("/vt start")
                end)
            end

            imgui.EndTabItem()
        end

        -- Viridian Rise Tab
        if imgui.BeginTabItem("Viridian Rise") then
            if imgui.BeginTable("Viridian Rise Table",2) then
                imgui.TableSetupColumn("Viridian Rise Buttons 1")
                imgui.TableSetupColumn("Viridian Rise Buttons 2")
                
                imgui.TableNextRow()
                imgui.TableSetColumnIndex(0)
                if imgui.Button("VR Use Portal") then
                    game.Actions.InvokeChat("/ub bc /ub uselp Viridian Portal")
                end
                imgui.Separator()

                imgui.TableSetColumnIndex(1)
                if imgui.Button("Return After Death") then
                    game.Actions.InvokeChat("/vt opt set enablenav true")
                    game.Actions.InvokeChat("/vtn deru")
                end
                imgui.Separator()

                imgui.TableNextRow()
                imgui.TableSetColumnIndex(0)
                if imgui.Button("Talk Marker") then
                    game.Actions.InvokeChat("/ub bc /ub uselp Marker")
                end
                imgui.Separator()

                imgui.TableSetColumnIndex(1)
                if imgui.Button("Level 5 Bridge") then
                    game.Actions.InvokeChat("/vt nav load navs\vr-bridge-jump")
                end
                imgui.Separator()

                imgui.TableNextRow()
                imgui.TableSetColumnIndex(0)
                if imgui.Button("Essence Looter") then
                    game.World.OnTick.Once(function()
                        game.Actions.InvokeChat("/ub bc /vto lootonlyrarecorpses true")
                        sleep(250)
                        game.Actions.InvokeChat("/ub bc /vto lootfellowcorpses true")
                        sleep(250)
                        game.Actions.InvokeChat("/vto lootonlyrarecorpses false")
                    end)
                end
                imgui.Separator()
                
                imgui.TableSetColumnIndex(1)
                if imgui.Button("Count Essences") then
                    game.Actions.InvokeChat("/ub bc /ub mexec $mcount=getitemcountininventorybyname[`Viridian Essence`]&&chatbox[`/f Viridian Essence Count: `+$mcount]")
                end
                imgui.Separator()

                imgui.TableNextRow()
                imgui.TableSetColumnIndex(0)
                if imgui.Button("VR Setmotion Left") then
                    game.World.OnTick.Once(function()
                        SlideDirection(0)
                    end)
                end

                imgui.TableSetColumnIndex(1)
                if imgui.Button("VR Setmotion Right") then
                    game.World.OnTick.Once(function()
                        SlideDirection(1)
                    end)
                end

                imgui.TableNextRow()
                imgui.TableSetColumnIndex(0)
                if imgui.Button("VR Setmotion") then
                    game.World.OnTick.Once(function()
                        SlideAway()
                    end)
                end

                imgui.EndTable()
            end

            imgui.EndTabItem()
        end

        if imgui.BeginTabItem("Gambling") then
            if imgui.Button("Buy High Stakes Tokens") then
                game.World.OnTick.Once(function()
                    local trade_note = game.Character.GetFirstInventory("Trade Note (250,000)")
                    local dealer = game.World.GetNearest("Arshid al-Qiyid",DistanceType.T2D)
                    if trade_note ~= nil and dealer ~= nil then
                        await(game.Actions.InvokeChat("/ub prepclick yes 10"))
                        await(game.Actions.ObjectGive(trade_note.Id,dealer.Id))
                    end
                end)
            end
            if imgui.Button("Gamble High Stakes") then
                game.World.OnTick.Once(function()
                    for _, value in ipairs(game.ActionQueue.Queue) do
                        game.ActionQueue.Remove(value)
                    end
                    local token = game.Character.GetFirstInventory("High-Stakes Gambling Token")
                    local gamemaster = game.World.GetNearest("Gharu'ndim High-Stakes Gamesmaster",DistanceType.T2D)
                    while token ~= nil and gamemaster ~= nil do
                        for _, value in ipairs(game.ActionQueue.Queue) do
                            game.ActionQueue.Remove(value)
                        end
                        token = game.Character.GetFirstInventory("High-Stakes Gambling Token")
                        game.Actions.ObjectGive(token.Id,gamemaster.Id)
                        sleep(300)
                    end
                end)
            end
            if imgui.Button("Drop Unwanted Items") then
                for index, value in pairs(dropItems) do
                    --print("Checking Item: "..index)
                    if game.Character.GetInventoryCount(index) > tonumber(value) then
                        game.ActionQueue.Add(game.Actions.ObjectDrop(game.Character.GetFirstInventory(index).Id))
                    end
                end
            end
            imgui.EndTabItem()
        end

        if imgui.BeginTabItem("Quests") then
            if imgui.Button("Eater Jaw (125)") then
                game.Actions.InvokeChat("/vt start")
                game.Actions.InvokeChat("/vt opt set enablebuffing false")
                game.Actions.InvokeChat("@buff")
                game.Actions.InvokeChat("/vt meta load quests\\q-eater-jaw-125")
            end
            imgui.EndTabItem()
        end

        imgui.EndTabBar()
    end

    if hudPosition == nil then
        imgui.SetWindowPos(Vector2.new(500,100))
        hudPosition = imgui.GetWindowPos()
    end
end)

hud.Visible = true

-- Assess all items
for _, object in ipairs(game.Character.Inventory) do
    if not object.HasAppraisalData then
        --print("appraising "..object.Name)
        await(object.Appraise())
    end
end
print("All Items Appraised!")