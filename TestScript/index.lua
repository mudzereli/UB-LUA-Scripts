local im = require("imgui")
local ubviews = require("utilitybelt.views")
local acc = require("acclient")
local imgui = im.ImGui
local version = "1.0.0"

local dropItems = {}
dropItems["Golden Gromnie"] = 0
dropItems["Chocolate Gromnie"] = 0
dropItems["Candy Corn"] = 0
dropItems["Licorice Rat"] = 0
dropItems["Ivory Gromnie Wings"] = 0
dropItems["Pack Scarecrow"] = 0
dropItems["Black Luster Pearl"] = 0
dropItems["Renegade Herbal Kit"] = 5
dropItems["Greater Mana Kit"] = 5
dropItems["Greater Stamina Kit"] = 5
dropItems["Massive Mana Charge"] = 10
dropItems["Mana Forge Key"] = 0
local doDropItems = false
local lootingColosseumVault = false
local lootColosseumVault = false
local turningInColoRings = false
local hudPosition = nil

-- Coroutine Manager
local coroutineQueue = {}

function StartCoroutine(func)
    local co = coroutine.create(func)
    table.insert(coroutineQueue, co)
end

function UpdateCoroutines()
    local i = 1
    while i <= #coroutineQueue do
        local co = coroutineQueue[i]
        if coroutine.status(co) == "dead" then
            table.remove(coroutineQueue, i)
        else
            local success, err = coroutine.resume(co)
            if not success then
                print("Coroutine Error: " .. err)
                table.remove(coroutineQueue, i)
            else
                i = i + 1
            end
        end
    end
end

-- Custom Wait Function
function Wait(ms)
    local targetTime = os.clock() + (ms / 1000)
    while os.clock() < targetTime do
        coroutine.yield()
    end
end


game.World.OnTick.Add(function() 
    if doDropItems then
        for index, value in pairs(dropItems) do
            --print("Checking Item: "..index)
            if game.Character.GetInventoryCount(index) > tonumber(value) then
                game.ActionQueue.Add(game.Actions.ObjectDrop(game.Character.GetFirstInventory(index).Id))
            end
        end
    end
end)

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
        print("Exiting Combat Mode")
        await(game.Actions.SetCombatMode(CombatMode.NonCombat))
        lootingColosseumVault = false
        return
    end

    -- Make Sure We're In Range
    local vault = game.World.GetNearest("Colosseum Vault")
    if vault == nil or vault.DistanceTo2D(game.Character.Weenie) > 5 then
        lootingColosseumVault = false
        lootColosseumVault = false
        print("Colosseum Vault Not Found or Too Far Away")
        return
    end

    -- Check Lock Status
    print("Appraising Colosseum Vault")
    await(game.Actions.ObjectAppraise(vault.Id))
    sleep(250)
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
    print("Colosseum Vault Locked: "..lockedstring)
    print("Colosseum Vault Open: "..openstring)

    local key = game.Character.GetFirstInventory("Colosseum Vault Key")
    -- If it's Locked + Not Open + No Key then We're Done
    if locked and not open and key == nil then
        print("Locked + Closed + No Key")
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
            print("Looting "..ring.Name)
            await(game.Actions.ObjectUse(ring.Id,0))
            Wait(750)
            lootingColosseumVault = false
            return
        else
            print("Closing "..vault.Name)
            await(game.Actions.InvokeChat("/ub mexec actiontryuseitem[wobjectgetopencontainer[]]"))
            Wait(250)
            lootingColosseumVault = false
            return
        end
    end

    -- If it's Locked but we have a Key, lets Unlock it
    if locked and key ~= nil then
        print("Unlocking "..vault.Name)
        await(game.Actions.ObjectUse(key.Id,vault.Id))
        Wait(250)
        lootingColosseumVault = false
        return
    end

    -- If it's Unlocked but Closed, let's Open it
    if not locked and not open then
        print("Opening "..vault.Name)
        await(game.Actions.ObjectUse(vault.Id,0))
        Wait(250)
        lootingColosseumVault = false
        return
    end
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
    local slidetime = 500
    StartCoroutine(function()
        game.Actions.InvokeChat("/ub bc /vtns")
        game.Actions.InvokeChat("/ub bc /vt opt set enablecombat false")
        game.Actions.InvokeChat("/ub bc /ub mexec clearmotion[]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[Backward,1]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[StrafeLeft,1]")
        Wait(slidetime) -- Custom Wait
        game.Actions.InvokeChat("/ub bc /ub mexec clearmotion[]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[Backward,1]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[StrafeLeft,0]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[StrafeRight,1]")
        Wait(slidetime) -- Custom Wait
        game.Actions.InvokeChat("/ub bc /ub mexec clearmotion[]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[Backward,1]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[StrafeLeft,1]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[StrafeRight,0]")
        Wait(slidetime) -- Custom Wait
        game.Actions.InvokeChat("/ub bc /ub mexec clearmotion[]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[Backward,1]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[StrafeLeft,0]")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[StrafeRight,1]")
        Wait(slidetime) -- Custom Wait
        game.Actions.InvokeChat("/ub bc /ub mexec clearmotion[]")
        game.Actions.InvokeChat("/ub bc /vt opt set enablecombat true")
        game.Actions.InvokeChat("/ub bc /ub follow Porkchop")
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
    StartCoroutine(function()
        game.Actions.InvokeChat("/ub bc /vtns")
        game.Actions.InvokeChat("/ub bc /vt opt set enablecombat false")
        game.Actions.InvokeChat("/ub bc /ub mexec setmotion[Backward,1]")
        game.Actions.InvokeChat(slidecommand)
        Wait(slidetime) -- Custom Wait
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
    UpdateCoroutines() -- Resume coroutines each frame

    if imgui.BeginTabBar("Main Tab") then

        -- Colo Helper Tab
        if imgui.BeginTabItem("Colo Helper") then

            if imgui.Button("Loot Colosseum Vault") then
                StartCoroutine(function()
                    lootColosseumVault = true
                    game.Actions.InvokeChat("/vt stop")
                    while lootColosseumVault do
                        if not lootingColosseumVault then
                            lootingColosseumVault = true
                            LootColosseumVault()
                        end
                        Wait(750) -- Custom Wait
                    end
                    game.Actions.InvokeChat("/vt start")
                end)
            end

            if imgui.Button("Add Ivory to Rings") then
                StartCoroutine(function()
                    game.ActionQueue.Dispose()
                    local applyingIvoryToRings = true
                    while applyingIvoryToRings do
                        applyingIvoryToRings = TryApplyIvoryToRings()
                        Wait(750)
                    end
                end)
            end

            if imgui.Button("Turn in Colo Rings") then
                StartCoroutine(function()
                    turningInColoRings = true
                    while turningInColoRings do
                        game.Actions.InvokeChat("/vt stop")
                        TurnInColoRings()
                        Wait(1000) -- Custom Wait
                    end
                    game.Actions.InvokeChat("/vt start")
                end)
            end

            if imgui.Button("Make Pyreal Nuggets") then
                StartCoroutine(function()
                    local makeNuggets = true
                    while makeNuggets do
                        game.Actions.InvokeChat("/vt stop")
                        MakePyrealNuggets()
                        Wait(250) -- Custom Wait
                        makeNuggets = game.Character.GetInventoryCount("Wrapped Pyreal Sliver") > 0 or game.Character.GetInventoryCount("Pyreal Sliver") > 0
                    end
                    game.Actions.InvokeChat("/vt start")
                end)
            end

            imgui.EndTabItem()
        end

        -- Viridian Rise Tab
        if imgui.BeginTabItem("Viridian Rise") then
            if imgui.Button("VR Use Portal") then
                game.Actions.InvokeChat("/ub bc /ub uselp Viridian Portal")
            end

            if imgui.Button("Essence Looter") then
                StartCoroutine(function()
                    game.Actions.InvokeChat("/ub bc /vto lootonlyrarecorpses true")
                    Wait(250)
                    game.Actions.InvokeChat("/ub bc /vto lootfellowcorpses true")
                    Wait(250)
                    game.Actions.InvokeChat("/vto lootonlyrarecorpses false")
                end)
            end

            if imgui.Button("Return After Death") then
                game.Actions.InvokeChat("/vt opt set enablenav true")
                game.Actions.InvokeChat("/vtn deru")
            end

            if imgui.Button("VR Setmotion Left") then
                SlideDirection(0)
            end

            if imgui.Button("VR Setmotion Right") then
                SlideDirection(1)
            end


            if imgui.Button("VR Setmotion") then
                SlideAway()
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