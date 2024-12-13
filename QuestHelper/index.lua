local im = require("imgui")
local ubviews = require("utilitybelt.views")
local imgui = im.ImGui
local version = "1.0.0"
local inputQuestText = "paste quest text here"
local inputQuestTextSize = Vector2.new(350,350)
local questSteps = {}

local hud = ubviews.Huds.CreateHud("QuestHelper v"..version)
hud.ShowInBar = true
hud.WindowSettings = im.ImGuiWindowFlags.AlwaysHorizontalScrollbar

hud.OnRender.Add(function ()
    if imgui.BeginTabBar("QuestHelper Tab Bar") then
        if imgui.BeginTabItem("Quest Steps") then
            for index, value in ipairs(questSteps) do
                local step = value[1]
                local check = value[2]


                -- Set up a wrapping region for the checkbox text
                imgui.PushTextWrapPos(imgui.GetContentRegionAvail().x)

                -- Begin a horizontal layout for checkbox and text
                imgui.PushID(index)
                local cbxChanged = imgui.Checkbox("##check" .. index, check)
                imgui.SameLine()
                imgui.TextWrapped(step)
                imgui.PopID()

                if not check then
                    if cbxChanged then
                        questSteps[index] = {step,not check}
                    end
                end
            
                -- Restore default wrap position
                imgui.PopTextWrapPos()
            end
            imgui.EndTabItem()
        end
        if imgui.BeginTabItem("Quest Text") then
            local questTextChanged, questTextResult = imgui.InputTextMultiline("Quest Text",inputQuestText,99999,inputQuestTextSize)
            if questTextChanged and type(questTextResult) == "string" then
                inputQuestText = questTextResult
                questSteps = {}
                for s in inputQuestText:gmatch("[^\r\n]+") do
                    table.insert(questSteps,{s,false})
                end
            end
            imgui.EndTabItem()
        end
        imgui.EndTabBar()
    end
end)