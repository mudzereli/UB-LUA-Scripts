local im = require("imgui")
local ubviews = require("utilitybelt.views")
local imgui = im.ImGui
local version = "1.0.3"
local inputQuestText = "paste quest text here"
local inputQuestTextSize = Vector2.new(350, 350)
local initSize = false
local questSteps = {}
local questStepsCompleted = {}

local hud = ubviews.Huds.CreateHud("QuestHelper v" .. version, 0x06006419)
hud.ShowInBar = true

hud.OnRender.Add(function()
    if not initSize then
        imgui.SetWindowSize(inputQuestTextSize)
        initSize = true
    end
    if imgui.BeginTabBar("QuestHelper Tab Bar") then
        if imgui.BeginTabItem("Quest Steps") then
            
            if imgui.BeginTable("ButtonTable",2) then
                imgui.TableSetupColumn("ButtonCol1")
                imgui.TableSetupColumn("ButtonCol2")
                imgui.TableNextRow()
                if questSteps[1] ~= nil then
                    imgui.TableNextColumn()
                    if imgui.Button("Say Current Step") then
                        game.Actions.InvokeChat(questSteps[1][1])
                    end
                end
                
                local numCompletedSteps = #questStepsCompleted
                if numCompletedSteps > 0 then
                    imgui.TableNextColumn()
                    if imgui.Button("Undo Last Check") then
                        if numCompletedSteps > 0 then
                            local step = questStepsCompleted[numCompletedSteps]
                            table.insert(questSteps,step[2],{step[1],false})
                            table.remove(questStepsCompleted,numCompletedSteps)
                        end
                    end
                end
                imgui.EndTable()
            end

            local i = 1
            while i <= #questSteps do
                local step = questSteps[i][1]
                local check = questSteps[i][2]

                -- Set up a wrapping region for the checkbox text
                imgui.PushTextWrapPos(imgui.GetContentRegionAvail().X)

                -- Begin a horizontal layout for checkbox and text
                imgui.PushID(i)
                local cbxChanged = imgui.Checkbox("##check" .. i, check)
                imgui.SameLine()
                imgui.TextWrapped(step)
                imgui.PopID()

                -- If the checkbox is checked, remove this step from the list
                if cbxChanged and not check then
                    table.remove(questSteps, i)
                    table.insert(questStepsCompleted,{step,i})
                else
                    i = i + 1
                end

                -- Restore default wrap position
                imgui.PopTextWrapPos()
            end
            imgui.EndTabItem()
        end

        if imgui.BeginTabItem("Quest Text") then
            local questTextChanged, questTextResult = imgui.InputTextMultiline("Quest Text", inputQuestText, 99999, inputQuestTextSize)
            if questTextChanged and type(questTextResult) == "string" then
                inputQuestText = questTextResult
                questSteps = {}
                questStepsCompleted = {}
                for s in inputQuestText:gmatch("[^\r\n]+") do
                    table.insert(questSteps, {s:gsub("%%","%%%%"), false})
                end
            end
            imgui.EndTabItem()
        end

        imgui.EndTabBar()
    end
end)
