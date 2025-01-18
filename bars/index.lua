local _imgui = require("imgui")
ImGui = _imgui.ImGui
local views = require("utilitybelt.views")
local io = require("filesystem").GetScript()
local settingsFile = "bar_settings.json"
local bars = require("bars")

---------------------------------------
--- icons
---------------------------------------

local textures = {}

---Get or create a managed texture for a world object
function GetOrCreateTexture(textureId)
  if textures[textureId] == nil then
    local texture ---@type ManagedTexture
    texture = views.Huds.GetIconTexture(textureId)
    textures[textureId] = texture
  end

  return textures[textureId]
end

function DrawIcon(bar,overrideId,size,func)
  --print(overrideId)
  if not size then 
    size = ImGui.GetContentRegionAvail()
  end

  local randIdBadIdea=ImGui.GetCursorScreenPos().X*ImGui.GetCursorScreenPos().Y
  if overrideId then
    local texture=GetOrCreateTexture(overrideId)
    if not texture then return end
    if ImGui.TextureButton("##"..randIdBadIdea, texture, size) then
      func()
    end
  elseif ImGui.TextureButton("##"..randIdBadIdea, GetOrCreateTexture(bar.icon), size) then
    bar:func()
  end
  if ImGui.IsItemClicked(1) and bar.rightclick then
    bar:rightclick()
  end

  local drawlist = ImGui.GetWindowDrawList()
  local rectMin = ImGui.GetItemRectMin()
  local rectMax = ImGui.GetItemRectMax()

  local textSize = ImGui.CalcTextSize(bar.label or " ")
  local startText = Vector2.new(
    rectMin.X + (rectMax.X - rectMin.X - textSize.X) / 2,
    rectMin.Y + (rectMax.Y - rectMin.Y - textSize.Y) / 2
  )
  if overrideId and bar.label then
    drawlist.AddRectFilled(rectMin,rectMax,0x88000000)
  end
  -- Draw text in white
  drawlist.AddText(startText, 0xFFFFFFFF, bar.label or "")
end

----------------------------------------
--- Settings Saving/Loading
----------------------------------------

-- Load settings from a JSON file
function loadSettings()
  local files = io.FileExists(settingsFile)
  if files then
    local content = io.ReadText(settingsFile)
    local settings = json.parse(content)
    if settings and settings[game.ServerName] and settings[game.ServerName][game.Character.Weenie.Name] then
      local characterSettings = settings[game.ServerName][game.Character.Weenie.Name]
      for i, bar in ipairs(bars) do
        if characterSettings[bar.name] then
          for key, value in pairs(characterSettings[bar.name]) do
            if type(value)=="table" and value.position and value.size then
              bar[key]={}
              bar[key].position=Vector2.new(value.position.X,value.position.Y)
              bar[key].size=Vector2.new(value.size.X,value.size.Y)
            elseif key=="position" then
              bar[key]=Vector2.new(value.X,value.Y)
            elseif key=="size" then
              bar[key]=Vector2.new(value.X,value.Y)
            else
              bar[key]=value
            end
          end
        end
      end
    end
  end
end

-- Function to pretty-print JSON (never omitted again!)
local function prettyPrintJSON(value, indent)
  local function wrapString(value)
    return '"' .. value:gsub('"', '\\"') .. '"'
  end

  indent = indent or ""
  local indentNext = indent .. "  "
  local items = {}

  if type(value) == "table" then
    local isArray = #value > 0
    for k, v in pairs(value) do
      local formattedKey = isArray and "" or wrapString(k) .. ": "
      table.insert(items, indentNext .. formattedKey .. prettyPrintJSON(v, indentNext))
    end
    if isArray then
      return "[\n" .. table.concat(items, ",\n") .. "\n" .. indent .. "]"
    else
      return "{\n" .. table.concat(items, ",\n") .. "\n" .. indent .. "}"
    end
  elseif type(value) == "string" then
    return wrapString(value)
  else
    return tostring(value)
  end
end

-- Save settings to a JSON file with prettification (indentation). Variable arguments passed as SaveBarSettings(bar,key,value,key2,value2,...)
function SaveBarSettings(barSaving,...)
  local args
  args=table.pack(...)
  if arg~=nil then
    if args.n~=0 and args.n%2==1 then
      print("Invalid number of arguments to save. Must be even")
      return
    end
  end

  local settings = {}
  local files = io.FileExists(settingsFile)
  if files then
    local content = io.ReadText(settingsFile)
    settings = json.parse(content) or {}
  end
  
  if not settings[game.ServerName] then
    settings[game.ServerName] = {}
  end
  if not settings[game.ServerName][game.Character.Weenie.Name] then
    settings[game.ServerName][game.Character.Weenie.Name] = {}
  end

  settings[game.ServerName][game.Character.Weenie.Name] = settings[game.ServerName][game.Character.Weenie.Name]

  if args then
    for i=1,args.n do
      if i%2==0 then
        if settings[game.ServerName][game.Character.Weenie.Name][barSaving.name]==nil then
          settings[game.ServerName][game.Character.Weenie.Name][barSaving.name]={}
        end
        settings[game.ServerName][game.Character.Weenie.Name][barSaving.name][args[i-1]]=args[i]
      end
    end
  end

  io.WriteText(settingsFile, prettyPrintJSON(settings))
end

-- Load settings when the script starts.
loadSettings()

----------------------------------------
--- ImGui Display Logic: Separate HUDs for Each Progress Bar
----------------------------------------

local function imguiAligner(bar, text, start, size)
  -- Default to current cursor position and content region if not provided
  start = start or ImGui.GetCursorScreenPos() or Vector2.new(0, 0) -- Ensure it's not nil
  size = size or ImGui.GetContentRegionAvail()

  -- Calculate the size of the text to align
  local textSize = ImGui.CalcTextSize(text)
  for _ in string.gmatch(text, "%.") do
    textSize.X = textSize.X - ImGui.GetFontSize() / 2
  end

  
  -- Calculate the X position to center the text, and ensure it doesn't overflow
  local textX
  if bar.textAlignment == "left" then
    textX = start.X -- Align text to the left
  elseif bar.textAlignment == "center" or bar.textAlignment == nil then
    -- Center the text horizontally, considering the available space
    textX = start.X + (size.X - textSize.X) / 2
    -- Ensure textX doesn't go below the start.X
    textX = math.max(textX, start.X)
  elseif bar.textAlignment == "right" then
    textX = start.X + size.X - textSize.X -- Align text to the right
  end

  -- Calculate the Y position to center the text vertically
  local textY = start.Y + (size.Y - textSize.Y) / 2

  -- Set the cursor to the calculated position
  ImGui.SetCursorScreenPos(Vector2.new(textX, textY))
end

---@type Hud[]
local huds = {} -- Initialize the huds table

-- Create HUDs for each bar as invisible windows
for i, bar in ipairs(bars) do
  if bar.icon then
    huds[i] = views.Huds.CreateHud(bar.name, bar.icon)
  else
    huds[i] = views.Huds.CreateHud(bar.name)
  end
  
  bar.hud=huds[i]
  huds[i].OnHide.Add(function()
    bar.hide = true
    SaveBarSettings(bar,"hide",bar.hide)
    huds[i].Visible = false
  end)
  huds[i].OnShow.Add(function()
    bar.hide = false
    SaveBarSettings(bar,"hide",bar.hide)
    huds[i].Visible = true    
  end)

  -- Set HUD properties.
  huds[i].Visible = not bar.hide
  huds[i].ShowInBar = true

  bar.imguiReset = true
  -- Pre-render setup for each HUD.
  huds[i].OnPreRender.Add(function()
    local zeroVector = Vector2.new(0, 0)
    ImGui.PushStyleVar(_imgui.ImGuiStyleVar.WindowMinSize, Vector2.new(1, ImGui.GetFontSize()))
    ImGui.PushStyleVar(_imgui.ImGuiStyleVar.WindowPadding, zeroVector)
    ImGui.PushStyleVar(_imgui.ImGuiStyleVar.FramePadding, zeroVector)
    ImGui.PushStyleVar(_imgui.ImGuiStyleVar.ItemSpacing, zeroVector)
    ImGui.PushStyleVar(_imgui.ImGuiStyleVar.ItemInnerSpacing, zeroVector)
    
    if bar.imguiReset then
      if bar.renderContext==nil then
        ImGui.SetNextWindowSize(bar.size and bar.size or Vector2.new(100, 100))
        ImGui.SetNextWindowPos(bar.position and bar.position or Vector2.new(100 + (i * 10), (i - 1) * 40))
      else
        ImGui.SetNextWindowSize(bar[bar.renderContext] and bar[bar.renderContext].size or Vector2.new(100, 100))
        ImGui.SetNextWindowPos(bar[bar.renderContext] and bar[bar.renderContext].position or Vector2.new(100 + (i * 10), (i - 1) * 40))
      end
      bar.imguiReset = false
    end

    -- Set flags to disable all unnecessary decorations.
    if ImGui.GetIO().KeyCtrl then
      huds[i].WindowSettings =
          _imgui.ImGuiWindowFlags.NoScrollbar +
          _imgui.ImGuiWindowFlags.NoCollapse
    else
      huds[i].WindowSettings =
          _imgui.ImGuiWindowFlags.NoTitleBar +
          _imgui.ImGuiWindowFlags.NoScrollbar + -- Prevent scrollbars explicitly.
          _imgui.ImGuiWindowFlags.NoMove +      -- Prevent moving unless Ctrl is pressed.
          _imgui.ImGuiWindowFlags.NoResize +    -- Prevent resizing unless Ctrl is pressed.
          _imgui.ImGuiWindowFlags.NoCollapse +
          (bar.windowSettings or 0)
    end
  end)

  if bar.init then
    bar:init()
    bar.init=nil
  end

  -- Render directly into the parent HUD window using BeginChild to anchor progress bars.
  huds[i].OnRender.Add(function()
    if ImGui.BeginChild(bar.name .. "##" .. i, Vector2.new(0, 0), false, huds[i].WindowSettings) then
      local fontScale = bar.fontScale or 1
      ImGui.SetWindowFontScale(fontScale)

      for _, style in ipairs(bar.stylevar or {}) do
        ImGui.PushStyleVar(style[1], type(style[2])=="function" and style[2](bar) or style[2])
      end
      for _,color in ipairs(bar.styleColor or {}) do
        ImGui.PushStyleColor(color[1],type(color[2])=="function" and color[2](bar) or color[2])
      end

      if bar.type == "progress" then
        ImGui.PushStyleColor(_imgui.ImGuiCol.PlotHistogram, bar.color)

        -- Render the progress bar inside the HUD without default text.
        local progressBarSize = Vector2.new(ImGui.GetContentRegionAvail().X, ImGui.GetContentRegionAvail().Y)
        local progressFraction = bar.value() / bar.max()
        local progressBarStartPos = ImGui.GetCursorScreenPos()   -- Save the starting position of the progress bar
        ImGui.ProgressBar(progressFraction, progressBarSize, "") -- Render bar without default text

        -- Calculate and render custom text based on alignment setting
        local text = bar.text and bar:text() or string.format("%.0f%%%%", progressFraction * 100)

        imguiAligner(bar, text, progressBarStartPos, progressBarSize)
        ImGui.Text(text)

        ImGui.PopStyleColor() -- Ensure this matches PushStyleColor()

      elseif bar.type == "button" then
        if bar.icon then
          DrawIcon(bar)
        elseif ImGui.Button(bar.text and bar:text() or bar.label, ImGui.GetContentRegionAvail()) then
          bar:func()
        end

      elseif bar.type == "text" then
        ---@diagnostic disable-next-line
        local text = bar:text()
        imguiAligner(bar, text)
        ImGui.Text(text)
      elseif bar.render then
        bar.render(bar)
      end

      for _,__ in ipairs(bar.styleColor or {}) do
        ImGui.PopStyleColor()
      end
      for _, __ in ipairs(bar.stylevar or {}) do
        ImGui.PopStyleVar()
      end
      
      -- Save position/size when Ctrl is pressed.
      if ImGui.GetIO().KeyCtrl then
        local currentPos = ImGui.GetWindowPos() - Vector2.new(0, ImGui.GetFontSize()/fontScale)
        local currentContentSize = ImGui.GetWindowSize() - Vector2.new(0, -ImGui.GetFontSize()/fontScale)
        if currentPos.X ~= (bar.position and bar.position.X or -1) or
            currentPos.Y ~= (bar.position and bar.position.Y or -1) or
            currentContentSize.X ~= (bar.size and bar.size.X or -1) or
            currentContentSize.Y ~= (bar.size and bar.size.Y or -1) then
          bar.position = currentPos
          bar.size = currentContentSize
          if bar.renderContext~=nil then
            bar[bar.renderContext]={position=Vector2.new(bar.position.X,bar.position.Y),size=Vector2.new(bar.size.X,bar.size.Y)}
            SaveBarSettings(bar,bar.renderContext,{position={X=bar.position.X,Y=bar.position.Y},size={X=bar.size.X,Y=bar.size.Y}})
          else 
            SaveBarSettings(bar, "position",{X=bar.position.X,Y=bar.position.Y},"size", {X=bar.size.X,Y=bar.size.Y})
          end
        end
      end
    end

    ImGui.EndChild()
    ImGui.PopStyleVar(5) --WindowMinSize,WindowPadding,FramePadding,ItemSpacing,ItemInnerSpacing
  end)
end

