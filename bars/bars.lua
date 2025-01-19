local _imgui = require("imgui")
local vitals = game.Character.Weenie.Vitals
local acclient = require("acclient")

-- ACTIONQUEUE CONFIG
local genericActionOpts = ActionOptions.new()
---@diagnostic disable
genericActionOpts.MaxRetryCount = 0
genericActionOpts.TimeoutMilliseconds = 100
---@diagnostic enable
local genericActionCallback = function(e)
  if not e.Success then
    if e.Error ~= ActionError.ItemAlreadyWielded then
      print("Fail! " .. e.ErrorDetails)
    end
  end
end

local equipmentActionOpts = ActionOptions.new()
---@diagnostic disable
equipmentActionOpts.MaxRetryCount = 3
equipmentActionOpts.TimeoutMilliseconds = 250
---@diagnostic enable


local function stagger(count, opts)
  local staggered = ActionOptions.new()
  if opts then
    staggered.TimeoutMilliseconds = opts.TimeoutMilliseconds * count
    staggered.MaxRetryCount = opts.MaxRetryCount
    staggered.SkipChecks = opts.SkipChecks
  else
    staggered.TimeoutMilliseconds = genericActionOpts.TimeoutMilliseconds * count
    staggered.MaxRetryCount = genericActionOpts.MaxRetryCount
    staggered.SkipChecks = genericActionOpts.SkipChecks
  end
  return staggered
end

-- FUNCTIONS USED BY BARS
local function sortbag(bar, inscription, containerHolder, func)
  if bar.sortBag == nil or game.World.Exists(bar.sortBag) == nil then
    for _, bag in ipairs(containerHolder.Containers) do
      game.Messages.Incoming.Item_SetAppraiseInfo.Until(function(e)
        if bag.Id == e.Data.ObjectId then
          if bag.Value(StringId.Inscription) == inscription then
            bar.sortBag = bag.Id
            SaveBarSettings(bar, "icon", bar.icon, "sortBag", bag.Id)
          end
          ---@diagnostic disable-next-line
          return true
        end
        ---@diagnostic disable-next-line
        return false
      end)

      bag.Appraise()
    end
  else
    func(bar)
  end
end

local function renderEvent(bar)                                                       -- used by floating combatTexts
  local currentTime = os.clock()
  local validEntries = {}                                                             -- Temporary list for valid entries
  local average = (bar.runningCount > 0) and (bar.runningSum / bar.runningCount) or 1 -- Avoid divide by zero

  -- Get the window's current size (content region)
  local windowSize = ImGui.GetContentRegionAvail()
  local lastEntry = nil
  local minSpacingX = 20

  -- Process and render each entry
  for i, entry in ipairs(bar.entries) do
    local elapsed = currentTime - entry.time
    if elapsed <= bar.fadeDuration then
      -- Calculate alpha for fade effect
      local alpha = 1 - (elapsed / bar.fadeDuration)
      local color = tonumber(
        string.format("%02X%s", math.floor(alpha * 255),
          entry.positive and bar.fontColorPositive_BBGGRRstring or bar.fontColorNegative_BBGGRRstring), 16)

      -- Scale font based on value relative to the average
      if not entry.scale then
        entry.scale = string.sub(entry.text, -1) == "!" and entry.fontScale_crit or
            math.min(math.max((entry.value or average) / average, bar.fontScale_min), bar.fontScale_max)
      end
      ImGui.SetWindowFontScale(entry.scale)

      -- Calculate the floating distance based on elapsed time and window size
      local floatDistance = (elapsed / bar.fadeDuration) * windowSize.Y -- Scale to the full window height

      -- Start the y position from the bottom of the window and move up
      entry.cursorPosY = windowSize.Y - floatDistance - ImGui.GetFontSize()

      if entry.cursorPosX == nil then
        -- Calculate horizontal position based on entry index
        entry.textSize = ImGui.CalcTextSize(entry.text)
        local baseX = (windowSize.X - entry.textSize.X) / 2 -- Center position
        entry.cursorPosX = baseX

        if lastEntry then
          local conflict = function()
            return (lastEntry.cursorPosY + lastEntry.textSize.Y - entry.cursorPosY) > 0 and
                (lastEntry.cursorPosX + lastEntry.textSize.X - entry.cursorPosX) > 0
          end
          if conflict() then
            entry.cursorPosX = baseX + lastEntry.textSize.X + minSpacingX
            if entry.cursorPosX + entry.textSize.X > windowSize.X or conflict() then
              entry.cursorPosX = lastEntry.cursorPosX - entry.textSize.X - minSpacingX
            end
          end
        end
      end

      -- Set the cursor position using SetCursorPos, relative to the window
      ImGui.SetCursorPos(Vector2.new(entry.cursorPosX, entry.cursorPosY))

      -- Render the text at the calculated position
      ImGui.PushStyleColor(_imgui.ImGuiCol.Text, color)
      ImGui.Text(entry.text)
      ImGui.PopStyleColor()

      -- Reset font scaling after rendering
      ImGui.SetWindowFontScale(1)

      -- Store the valid entry for the next render cycle
      table.insert(validEntries, entry)
    else
      -- Remove expired entry from running sum and count
      if entry.value and bar.runningCount > 10 then
        bar.runningSum = bar.runningSum - entry.value
        bar.runningCount = bar.runningCount - 1
      end
    end
    lastEntry = entry
  end

  -- Replace old entries with the valid ones
  bar.entries = validEntries
end

-- INITIALIZATION STUFF FOR TO BE ABLE TO SEE PARENT
-- Create the bars table with a metatable
local bars = setmetatable({}, {
  -- When adding new entries, ensure parent and index by name
  __newindex = function(t, k, v)
    if type(v) == "table" and v.name then
      rawset(t, v.name, v) -- Index the bar by its name
      v.parent = t         -- Set the parent reference
    end
    rawset(t, k, v)         -- Add to the array
  end,
  
  -- Initialize with multiple entries
  __call = function(t, initialValues)
    for _, v in ipairs(initialValues) do
      table.insert(t, v) -- Triggers __newindex
    end
  end
})

-- BARS -- ENSURE EACH BAR HAS A UNIQUE NAME OR IT'LL FUCK UP BAD
bars({
  {
    name           = "Health",
    color          = 0xAA0000AA,
    icon           = 0x060069E9,
    windowSettings = _imgui.ImGuiWindowFlags.NoInputs + _imgui.ImGuiWindowFlags.NoBackground,
    textAlignment  = "center",
    type           = "progress",
    stylevar       = {
      { _imgui.ImGuiStyleVar.FrameBorderSize, 2 }
    },
    styleColor     = {
      { _imgui.ImGuiCol.Border, 0xFFFFFFFF }
    },
    max            = function() return vitals[VitalId.Health].Max end,
    value          = function() return vitals[VitalId.Health].Current end,
    text           = function() return "  " .. vitals[VitalId.Health].Current .. " / " .. vitals[VitalId.Health].Max end --.. " (" .. string.format("%.0f%%%%",(vitals[VitalId.Health].Current)/(vitals[VitalId.Health].Max)*100) ..")" end

  },                                                                                                                     -- add "fontScale = 1.5" property to scale font 1.5x to any bar (or any other size), as needed
  {
    name           = "Stamina",
    color          = 0xAA00AAAA,
    icon           = 0x060069E8,
    windowSettings = _imgui.ImGuiWindowFlags.NoInputs + _imgui.ImGuiWindowFlags.NoBackground,
    textAlignment  = "center",
    type           = "progress",
    stylevar       = {
      { _imgui.ImGuiStyleVar.FrameBorderSize, 2 }
    },
    styleColor     = {
      { _imgui.ImGuiCol.Border, 0xFFFFFFFF }
    },
    max            = function() return vitals[VitalId.Stamina].Max end,
    value          = function() return vitals[VitalId.Stamina].Current end,
    text           = function() return "  " .. vitals[VitalId.Stamina].Current .. " / " .. vitals[VitalId.Stamina].Max end --.. " (" .. string.format("%.0f%%%%",(vitals[VitalId.Stamina].Current)/(vitals[VitalId.Stamina].Max)*100) ..")" end
  },
  {
    name           = "Mana",
    color          = 0xAAAA0000,
    icon           = 0x060069EA,
    windowSettings = _imgui.ImGuiWindowFlags.NoInputs + _imgui.ImGuiWindowFlags.NoBackground,
    textAlignment  = "center",
    type           = "progress",
    stylevar       = {
      { _imgui.ImGuiStyleVar.FrameBorderSize, 2 }
    },
    styleColor     = {
      { _imgui.ImGuiCol.Border, 0xFFFFFFFF }
    },
    max            = function() return vitals[VitalId.Mana].Max end,
    value          = function() return vitals[VitalId.Mana].Current end,
    text           = function() return "  " .. vitals[VitalId.Mana].Current .. " / " .. vitals[VitalId.Mana].Max end --.. " (" .. string.format("%.0f%%%%",(vitals[VitalId.Mana].Current)/(vitals[VitalId.Mana].Max)*100) ..")" end
  },
  {
    name = "render_damageDealt",
    icon = 0x060028FC,
    fontScale_min = 2,
    fontScale_max = 3,
    fontScale_crit = 4,
    text = function(bar) return " " end,
    fontColorPositive_BBGGRRstring = "FFFFFF",
    fontColorNegative_BBGGRRstring = "0000FF",
    fadeDuration = 2, -- How long the text stays on screen
    floatSpeed = 1,   -- Speed of the floating text
    entries = {},     -- Table to store damages
    runningSum = 0,   -- Sum of all values (for average calculation)
    runningCount = 0, -- Count of all values (for average calculation)

    init = function(bar)
      -- Set window properties
      bar.windowSettings =
          _imgui.ImGuiWindowFlags.NoInputs +
          _imgui.ImGuiWindowFlags.NoBackground

      ---@diagnostic disable:param-type-mismatch

      local function hpExtractor(e)
        ---@diagnostic disable:undefined-field
        ---@diagnostic disable:inject-field

        local damage = nil
        local mobName
        local crit = false
        if e.Data.Name ~= nil then
          mobName = e.Data.Name
          damage = e.Data.DamageDone
        elseif (e.Data.Type == LogTextType.Magic or e.Data.Type == LogTextType.CombatSelf) then
          local r = Regex.new(
            "^(?<crit>Critical hit!  )?(?:[^!]+! )*(?:(?:You (?:eradicate|wither|twist|scar|hit|mangle|slash|cut|scratch|gore|impale|stab|nick|crush|smash|bash|graze|incinerate|burn|scorch|singe|freeze|frost|chill|numb|dissolve|corrode|sear|blister|blast|jolt|shock|spark) (?<mobName>.*?) for (?<damage>[\\d,]+) points (?:.*))|(?:With .*? you (?:drain|exhaust|siphon|deplete) (?<drainDamage>[\\d,]+) points of health from (?<magicMobName>.*?))\\.)$"
          )
          local m = r.Match(e.Data.Text)
          if (m.Success) then
            if m.Groups["crit"].Success then
              crit = true
            end
            if m.Groups["damage"].Success then
              damage = m.Groups["damage"].Value
            elseif m.Groups["drainDamage"].Value then
              damage = m.Groups["drainDamage"].Value
            end
          end
        end
        ---@diagnostic enable:undefined-field
        ---@diagnostic enable:inject-field
        if damage ~= nil then
          table.insert(bar.entries, {
            text = damage .. (crit and "!" or ""),
            value = math.abs(tonumber(damage or 0)), -- Store the absolute value for scaling
            positive = tonumber(damage) > 0,
            time = os.clock(),
          })
          -- Update the running sum and count
          bar.runningSum = bar.runningSum + math.abs(tonumber(damage or 0))
          bar.runningCount = bar.runningCount + 1
        end
      end

      game.Messages.Incoming.Combat_HandleAttackerNotificationEvent.Add(hpExtractor)
      game.Messages.Incoming.Communication_TextboxString.Add(hpExtractor)

      game.Messages.Incoming.Combat_HandleEvasionAttackerNotificationEvent.Add(function(e)
        table.insert(bar.entries, {
          text = "Evade",
          positive = false,
          time = os.clock(),
        })
      end)
      game.Messages.Incoming.Combat_HandleVictimNotificationEventOther.Add(function(e)
        if game.Character.Weenie.Vitals[VitalId.Health].Current ~= 0 then --initial lazy check it's not me who died. i do not think this would work
          table.insert(bar.entries, {
            text = "RIP",
            positive = false,
            time = os.clock()
          })
        end
      end)
      ---@diagnostic enable:param-type-mismatch
    end,

    render = renderEvent
  },
  {
    name = "render_damageTaken",
    icon = 0x060028FD,
    fontScale_min = 2,
    fontScale_max = 3,
    text = function(bar) return " " end,
    fontColorPositive_BBGGRRstring = "00FF00",
    fontColorNegative_BBGGRRstring = "0000FF",
    fadeDuration = 2, -- How long the text stays on screen
    floatSpeed = 1,   -- Speed of the floating text
    entries = {},     -- Table to store hp changes
    runningSum = 0,   -- Sum of all values (for average calculation)
    runningCount = 0, -- Count of all values (for average calculation)

    init = function(bar)
      -- Set window properties
      bar.windowSettings =
          _imgui.ImGuiWindowFlags.NoInputs +
          _imgui.ImGuiWindowFlags.NoBackground

      -- Subscribe to stamina change events
      game.Character.OnVitalChanged.Add(function(changedVital)
        if changedVital.Type == VitalId.Health then
          local delta = changedVital.Value - changedVital.OldValue
          table.insert(bar.entries, {
            text = tostring(delta),
            value = math.abs(delta), -- Store the absolute value for scaling
            positive = delta > 0,
            time = os.clock(),
          })
          -- Update the running sum and count
          bar.runningSum = bar.runningSum + math.abs(delta)
          bar.runningCount = bar.runningCount + 1
        end
      end)
    end,

    render = renderEvent
  },
  {
    name = "buffs",
    icon = 0x06005E6B,
    windowSettings = _imgui.ImGuiWindowFlags.NoInputs + _imgui.ImGuiWindowFlags.NoBackground,
    init = function(bar)
      bar.growAxis = "X"
      bar.growReverse = false
      bar.bufferRect = Vector2.new(10,5)
      bar.iconSpacing = 10
      bar.expiryMaxSeconds = 60
      bar.spellLevelDisplay = true
      bar.spellLevelColor = 0xBBBBBBBB
      bar.buffBorder = true
      bar.buffBorderColor = 0x99009900
      bar.buffBorderThickness = 2
      bar.displayCriteria = function(enchantment, spell, entry)
        return ((enchantment.Duration ~= -1) and (SpellFlags.Beneficial + spell.Flags == spell.Flags) and ((not bar.expiryMaxSeconds) or entry.ExpiresAt<bar.expiryMaxSeconds))
      end

      function bar.formatSeconds(seconds)
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        local remainingSeconds = seconds % 60
        if hours > 0 then
          return string.format("%02d:%02d", hours, minutes)
        elseif minutes>0 then
          return string.format("%02d:%02d", minutes, remainingSeconds)
        else
          return string.format("%ds", remainingSeconds)
        end
      end
    end,
    render = function(bar)
      local buffs = {}

      ---@param enchantment Enchantment
      for _, enchantment in ipairs(game.Character.ActiveEnchantments()) do
        ---@type Spell
        local spell = game.Character.SpellBook.Get(enchantment.SpellId)
        
        local entry = {}
        entry.ClientReceivedAt = enchantment.ClientReceivedAt
        entry.Duration = enchantment.Duration
        entry.StartTime = enchantment.StartTime
        if entry.Duration > -1 then
          entry.ExpiresAt = (entry.ClientReceivedAt + TimeSpan.FromSeconds(entry.StartTime + entry.Duration) - DateTime.UtcNow).TotalSeconds
        else
          entry.ExpiresAt = 999999
        end

        if bar.displayCriteria(enchantment,spell,entry) then
          entry.Name = spell.Name or "Unknown"
          entry.Id = spell.Id or "No spell.Id"
          entry.Level = ({"I","II","III","IV","V","VI","VII","VIII"})[spell.Level]

          entry.icon = spell.Icon or 9914

          local function hasFlag(object, flag)
            return (object.Flags + flag == object.Flags)
          end

          local statKey = spell.StatModKey
          if spell.StatModAttribute ~= AttributeId.Undef then
            entry.stat = tostring(AttributeId.Undef + statKey)
          elseif spell.StatModVital ~= Vital.Undef then
            entry.stat = tostring(Vital.Undef + statKey)
          elseif spell.StatModSkill ~= SkillId.Undef then
            entry.stat = tostring(SkillId.Undef + statKey)
          elseif spell.StatModIntProp ~= IntId.Undef then
            entry.stat = tostring(IntId.Undef + statKey)
          elseif spell.StatModFloatProp ~= FloatId.Undef then
            entry.stat = tostring(FloatId.Undef + statKey)
          else
            entry.stat = tostring(enchantment.Category)
          end

          if hasFlag(enchantment, EnchantmentFlags.Additive) then
            entry.printProp = enchantment.StatValue > 0 and ("+" .. enchantment.StatValue) or enchantment.StatValue
          elseif hasFlag(enchantment, EnchantmentFlags.Multiplicative) then
            local percent = enchantment.StatValue - 1
            entry.printProp = (percent > 0 and ("+" .. string.format("%.0d", percent * 100)) or string.format("%.0d", percent * 100)) .. "%%"
          end

          table.insert(buffs, entry)
        end
      end

      table.sort(buffs, function(a, b)
        return a.ClientReceivedAt < b.ClientReceivedAt
      end)
      
      local windowPos = ImGui.GetWindowPos()+Vector2.new(5,5)
      local windowSize = ImGui.GetContentRegionAvail()
      local minX,minY
      local maxX,maxY
      local iconSize = Vector2.new(28, 28)

      ImGui.BeginChild("ScrollableChild", ImGui.GetContentRegionAvail(), true)
      
      for i, buff in ipairs(buffs) do
        local cursorStartX,cursorStartY
        local expiryTimer = (buff.ClientReceivedAt + TimeSpan.FromSeconds(buff.StartTime + buff.Duration) - DateTime.UtcNow).TotalSeconds
        local spellLevelSize = ImGui.CalcTextSize(buff.Level)

        local reservedPerIconX = iconSize.X + bar.bufferRect.X/2 + bar.iconSpacing
        local reservedPerIconY = iconSize.Y + bar.bufferRect.Y/2 + bar.iconSpacing + ImGui.GetTextLineHeight()*1.5
        if bar.growAxis == "X" then
          if not bar.growReverse then 
            cursorStartX = windowPos.X + (i-1)*reservedPerIconX
            cursorStartY = windowPos.Y
            if i>1 and (cursorStartX + reservedPerIconX) > (windowPos.X+windowSize.X) then
              local iconsPerRow = math.floor(windowSize.X / reservedPerIconX) 
              local rowOffset=1
              while rowOffset<i and iconsPerRow*rowOffset<i do
                rowOffset=rowOffset+1
              end
              cursorStartX = windowPos.X + math.floor((i-1)-iconsPerRow*rowOffset+iconsPerRow)*reservedPerIconX
              cursorStartY = windowPos.Y + (rowOffset-1)*reservedPerIconY
            end
          else --reverse X
            cursorStartX = windowPos.X + windowSize.X - i*reservedPerIconX
            cursorStartY = windowPos.Y
            if i>1 and cursorStartX < windowPos.X then
              local iconsPerRow = math.floor(windowSize.X / reservedPerIconX) 
              local rowOffset=1
              while rowOffset<i and iconsPerRow*rowOffset<i do
                rowOffset=rowOffset+1
              end
              cursorStartX = windowPos.X + windowSize.X - math.floor(i-iconsPerRow*rowOffset+iconsPerRow)*reservedPerIconX
              cursorStartY = windowPos.Y + (rowOffset-1)*reservedPerIconY
            end
          end
        else --growAxis Y
          if not bar.growReverse then 
            cursorStartX = windowPos.X 
            cursorStartY = windowPos.Y + (i-1)*reservedPerIconY
            if i>1 and (cursorStartY + reservedPerIconY) > (windowPos.Y+windowSize.Y) then
              local iconsPerCol = math.floor(windowSize.Y / reservedPerIconY) 
              local colOffset=1
              while colOffset<i and iconsPerCol*colOffset<i do
                colOffset=colOffset+1
              end
              cursorStartX = windowPos.X + (colOffset-1)*reservedPerIconX
              cursorStartY = windowPos.Y + (colOffset-1)*math.floor((i-1)-iconsPerCol*colOffset+iconsPerCol)*reservedPerIconY
            end
          else -- reverse Y
            cursorStartX = windowPos.X 
            cursorStartY = windowPos.Y + windowSize.Y - i*reservedPerIconY
            if i>1 and cursorStartY < windowPos.Y then
              local iconsPerCol = math.floor(windowSize.Y / reservedPerIconY) 
              local colOffset=1
              while colOffset<i and iconsPerCol*colOffset<i do
                colOffset=colOffset+1
              end
              cursorStartX = windowPos.X + (colOffset-1)*reservedPerIconX
              cursorStartY = windowPos.Y + windowSize.Y - (colOffset-1)*math.floor(i-iconsPerCol*colOffset+iconsPerCol)*reservedPerIconY
            end
          end
        end

        if not minX or minX>cursorStartX then
          minX = cursorStartX
        end
        if not minY or minY>cursorStartY then
          minY = cursorStartY
        end
        if not maxX or maxX<cursorStartX then
          maxX = cursorStartX
        end
        if not maxY or maxY<cursorStartY then
          maxY = cursorStartY
        end  
        
        local cursorStart = Vector2.new(cursorStartX,cursorStartY)
        ImGui.GetWindowDrawList().AddRectFilled(cursorStart,cursorStart+iconSize+bar.bufferRect+Vector2.new(0,ImGui.GetTextLineHeight()+spellLevelSize.Y/2),0xAA000000)

        ImGui.SetCursorScreenPos(cursorStart+bar.bufferRect/2+Vector2.new(0,spellLevelSize.Y/2))--+Vector2.new(expirySize.X>iconSize.X and (iconSize.X-expirySize.X)/2 or 0,0))
        local cursorAfterRect = ImGui.GetCursorScreenPos()
        ImGui.TextureButton("##buff" .. buff.Id, GetOrCreateTexture(buff.icon), iconSize)
        if ImGui.IsItemHovered() then
          ImGui.BeginTooltip()

          ImGui.Text(buff.Name)
          ImGui.Text(buff.stat)
          ImGui.SameLine()
          ImGui.PushStyleColor(_imgui.ImGuiCol.Text,0xFF00FF00)
          ImGui.Text(" "..buff.printProp)
          ImGui.PopStyleColor()

          ImGui.EndTooltip()
        end
        if bar.spellLevelDisplay and buff.Level then
          ImGui.SetCursorScreenPos(cursorStart + Vector2.new(spellLevelSize.X/2,0))--Vector2.new(0,spellLevelSize.Y/2))--Vector2.new(0,spellLevelSize.Y))
          ImGui.PushStyleColor(_imgui.ImGuiCol.Text,bar.spellLevelColor)
          ImGui.Text(buff.Level)
          ImGui.PopStyleColor()
        end

        ImGui.SetCursorScreenPos(cursorAfterRect + Vector2.new(0, iconSize.Y))
        ImGui.Text(bar.formatSeconds(expiryTimer))

      end
      ImGui.EndChild()

      if bar.buffBorder and minX and minY and maxX and maxY then
        ImGui.GetWindowDrawList().AddRect(Vector2.new(minX-3,minY-3),Vector2.new(maxX+1+iconSize.X+bar.bufferRect.X,maxY+1+iconSize.Y+bar.bufferRect.Y+ImGui.GetTextLineHeight()*1.5),bar.buffBorderColor or 0x99009900,0,0,bar.buffBorderThickness or 2)
      end
    end
  },
  {
    name = "debuffs",
    icon = 0x06005E6A,
    windowSettings = _imgui.ImGuiWindowFlags.NoInputs + _imgui.ImGuiWindowFlags.NoBackground,
    init = function(bar)
      bar.growAxis = "X"
      bar.growReverse = false
      bar.bufferRect = Vector2.new(10,5)
      bar.iconSpacing = 10
      --bar.expiryMaxSeconds = 600
      bar.spellLevelDisplay = true
      bar.spellLevelColor = 0xBBBBBBBB
      bar.buffBorder = true
      bar.buffBorderColor = 0x99000099
      bar.buffBorderThickness = 2
      bar.displayCriteria = function(enchantment, spell, entry)
        return ((enchantment.Duration ~= -1) and (not (SpellFlags.Beneficial + spell.Flags == spell.Flags)) and ((not bar.expiryMaxSeconds) or entry.ExpiresAt<bar.expiryMaxSeconds))
      end

      function bar.formatSeconds(seconds)
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        local remainingSeconds = seconds % 60
        if hours > 0 then
          return string.format("%02d:%02d", hours, minutes)
        elseif minutes>0 then
          return string.format("%02d:%02d", minutes, remainingSeconds)
        else
          return string.format("%ds", remainingSeconds)
        end
      end
    end,
    render = function(bar)
      local buffs = {}

      ---@param enchantment Enchantment
      for _, enchantment in ipairs(game.Character.ActiveEnchantments()) do
        ---@type Spell
        local spell = game.Character.SpellBook.Get(enchantment.SpellId)
        
        local entry = {}
        entry.ClientReceivedAt = enchantment.ClientReceivedAt
        entry.Duration = enchantment.Duration
        entry.StartTime = enchantment.StartTime
        if entry.Duration > -1 then
          entry.ExpiresAt = (entry.ClientReceivedAt + TimeSpan.FromSeconds(entry.StartTime + entry.Duration) - DateTime.UtcNow).TotalSeconds
        else
          entry.ExpiresAt = 999999
        end

        if bar.displayCriteria(enchantment,spell,entry) then
          entry.Name = spell.Name or "Unknown"
          entry.Id = spell.Id or "No spell.Id"
          entry.Level = ({"I","II","III","IV","V","VI","VII","VIII"})[spell.Level]

          entry.icon = spell.Icon or 9914

          local function hasFlag(object, flag)
            return (object.Flags + flag == object.Flags)
          end

          local statKey = spell.StatModKey
          if spell.StatModAttribute ~= AttributeId.Undef then
            entry.stat = tostring(AttributeId.Undef + statKey)
          elseif spell.StatModVital ~= Vital.Undef then
            entry.stat = tostring(Vital.Undef + statKey)
          elseif spell.StatModSkill ~= SkillId.Undef then
            entry.stat = tostring(SkillId.Undef + statKey)
          elseif spell.StatModIntProp ~= IntId.Undef then
            entry.stat = tostring(IntId.Undef + statKey)
          elseif spell.StatModFloatProp ~= FloatId.Undef then
            entry.stat = tostring(FloatId.Undef + statKey)
          else
            entry.stat = tostring(enchantment.Category)
          end

          if hasFlag(enchantment, EnchantmentFlags.Additive) then
            entry.printProp = enchantment.StatValue > 0 and ("+" .. enchantment.StatValue) or enchantment.StatValue
          elseif hasFlag(enchantment, EnchantmentFlags.Multiplicative) then
            local percent = enchantment.StatValue - 1
            entry.printProp = (percent > 0 and ("+" .. string.format("%.0d", percent * 100)) or string.format("%.0d", percent * 100)) .. "%%"
          end

          table.insert(buffs, entry)
        end
      end

      table.sort(buffs, function(a, b)
        return a.ClientReceivedAt < b.ClientReceivedAt
      end)
      
      local windowPos = ImGui.GetWindowPos()+Vector2.new(5,5)
      local windowSize = ImGui.GetContentRegionAvail()
      local minX,minY
      local maxX,maxY
      local iconSize = Vector2.new(28, 28)

      ImGui.BeginChild("ScrollableChild", ImGui.GetContentRegionAvail(), true)
      for i, buff in ipairs(buffs) do
        local cursorStartX,cursorStartY
        local expiryTimer = (buff.ClientReceivedAt + TimeSpan.FromSeconds(buff.StartTime + buff.Duration) - DateTime.UtcNow).TotalSeconds
        local spellLevelSize = ImGui.CalcTextSize(buff.Level)

        local reservedPerIconX = iconSize.X + bar.bufferRect.X/2 + bar.iconSpacing
        local reservedPerIconY = iconSize.Y + bar.bufferRect.Y/2 + bar.iconSpacing + ImGui.GetTextLineHeight()*1.5
        if bar.growAxis == "X" then
          if not bar.growReverse then 
            cursorStartX = windowPos.X + (i-1)*reservedPerIconX
            cursorStartY = windowPos.Y
            if i>1 and (cursorStartX + reservedPerIconX) > (windowPos.X+windowSize.X) then
              local iconsPerRow = math.floor(windowSize.X / reservedPerIconX) 
              local rowOffset=1
              while rowOffset<i and iconsPerRow*rowOffset<i do
                rowOffset=rowOffset+1
              end
              cursorStartX = windowPos.X + math.floor((i-1)-iconsPerRow*rowOffset+iconsPerRow)*reservedPerIconX
              cursorStartY = windowPos.Y + (rowOffset-1)*reservedPerIconY
            end
          else --reverse X
            cursorStartX = windowPos.X + windowSize.X - i*reservedPerIconX
            cursorStartY = windowPos.Y
            if i>1 and cursorStartX < windowPos.X then
              local iconsPerRow = math.floor(windowSize.X / reservedPerIconX) 
              local rowOffset=1
              while rowOffset<i and iconsPerRow*rowOffset<i do
                rowOffset=rowOffset+1
              end
              cursorStartX = windowPos.X + windowSize.X - math.floor(i-iconsPerRow*rowOffset+iconsPerRow)*reservedPerIconX
              cursorStartY = windowPos.Y + (rowOffset-1)*reservedPerIconY
            end
          end
        else --growAxis Y
          if not bar.growReverse then 
            cursorStartX = windowPos.X 
            cursorStartY = windowPos.Y + (i-1)*reservedPerIconY
            if i>1 and (cursorStartY + reservedPerIconY) > (windowPos.Y+windowSize.Y) then
              local iconsPerCol = math.floor(windowSize.Y / reservedPerIconY) 
              local colOffset=1
              while colOffset<i and iconsPerCol*colOffset<i do
                colOffset=colOffset+1
              end
              cursorStartX = windowPos.X + (colOffset-1)*reservedPerIconX
              cursorStartY = windowPos.Y + (colOffset-1)*math.floor((i-1)-iconsPerCol*colOffset+iconsPerCol)*reservedPerIconY
            end
          else -- reverse Y
            cursorStartX = windowPos.X 
            cursorStartY = windowPos.Y + windowSize.Y - i*reservedPerIconY
            if i>1 and cursorStartY < windowPos.Y then
              local iconsPerCol = math.floor(windowSize.Y / reservedPerIconY) 
              local colOffset=1
              while colOffset<i and iconsPerCol*colOffset<i do
                colOffset=colOffset+1
              end
              cursorStartX = windowPos.X + (colOffset-1)*reservedPerIconX
              cursorStartY = windowPos.Y + windowSize.Y - (colOffset-1)*math.floor(i-iconsPerCol*colOffset+iconsPerCol)*reservedPerIconY
            end
          end
        end

        if not minX or minX>cursorStartX then
          minX = cursorStartX
        end
        if not minY or minY>cursorStartY then
          minY = cursorStartY
        end
        if not maxX or maxX<cursorStartX then
          maxX = cursorStartX
        end
        if not maxY or maxY<cursorStartY then
          maxY = cursorStartY
        end  

        local cursorStart = Vector2.new(cursorStartX,cursorStartY)
        ImGui.GetWindowDrawList().AddRectFilled(cursorStart,cursorStart+iconSize+bar.bufferRect+Vector2.new(0,ImGui.GetTextLineHeight()+spellLevelSize.Y/2),0xAA000000)

        ImGui.SetCursorScreenPos(cursorStart+bar.bufferRect/2+Vector2.new(0,spellLevelSize.Y/2))--+Vector2.new(expirySize.X>iconSize.X and (iconSize.X-expirySize.X)/2 or 0,0))
        local cursorAfterRect = ImGui.GetCursorScreenPos()
        ImGui.TextureButton("##buff" .. buff.Id, GetOrCreateTexture(buff.icon), iconSize)
        if ImGui.IsItemHovered() then
          ImGui.BeginTooltip()

          ImGui.Text(buff.Name)
          ImGui.Text(buff.stat)
          ImGui.SameLine()
          ImGui.PushStyleColor(_imgui.ImGuiCol.Text,0xFF00FF00)
          ImGui.Text(" "..buff.printProp)
          ImGui.PopStyleColor()

          ImGui.EndTooltip()
        end
        if bar.spellLevelDisplay and buff.Level then
          ImGui.SetCursorScreenPos(cursorStart + Vector2.new(spellLevelSize.X/2,0))--Vector2.new(0,spellLevelSize.Y/2))--Vector2.new(0,spellLevelSize.Y))
          ImGui.PushStyleColor(_imgui.ImGuiCol.Text,bar.spellLevelColor)
          ImGui.Text(buff.Level)
          ImGui.PopStyleColor()
        end

        ImGui.SetCursorScreenPos(cursorAfterRect + Vector2.new(0, iconSize.Y))
        ImGui.Text(bar.formatSeconds(expiryTimer))

      end
      ImGui.EndChild()
      if bar.buffBorder and minX and minY and maxX and maxY then
        ImGui.GetWindowDrawList().AddRect(Vector2.new(minX-3,minY-3),Vector2.new(maxX+1+iconSize.X+bar.bufferRect.X,maxY+1+iconSize.Y+bar.bufferRect.Y+ImGui.GetTextLineHeight()*1.5),bar.buffBorderColor or 0x99000099,0,0,bar.buffBorderThickness or 2)
      end
    end
  },
})

return bars


--table.insert(entry.printProps,tostring(enchantment.Duration))

--[[if #entry.printProps==0 then
            if enchantment.LayeredId~=nil then table.insert(entry.printProps,"LayeredId:"..tostring(enchantment.LayeredId)) end
            if enchantment.SpellId~=nil then table.insert(entry.printProps,"SpellId:"..tostring(enchantment.SpellId)) end
            if enchantment.Layer~=nil then table.insert(entry.printProps,"Layer:"..tostring(enchantment.Layer)) end
            if enchantment.HasSpellSetId~=nil then table.insert(entry.printProps,"HasSpellSetId:"..tostring(enchantment.HasSpellSetId)) end
            if enchantment.Category~=nil then table.insert(entry.printProps,"Category:"..tostring(enchantment.Category)) end
            if enchantment.Power~=nil then table.insert(entry.printProps,"Power:"..tostring(enchantment.Power)) end
            if enchantment.StartTime~=nil then table.insert(entry.printProps,"StartTime:"..tostring(enchantment.StartTime)) end
            if enchantment.Duration~=nil then table.insert(entry.printProps,"Duration:"..tostring(enchantment.Duration)) end
            if enchantment.CasterId~=nil then table.insert(entry.printProps,"CasterId:"..game.World.Get(enchantment.CasterId).Name) end
            if enchantment.DegradeModifier~=nil then table.insert(entry.printProps,"DegradeModifier:"..tostring(enchantment.DegradeModifier)) end
            if enchantment.DegradeLimit~=nil then table.insert(entry.printProps,"DegradeLimit:"..tostring(enchantment.DegradeLimit)) end
            if enchantment.LastTimeDegraded~=nil then table.insert(entry.printProps,"LastTimeDegraded:"..tostring(enchantment.LastTimeDegraded)) end
            if enchantment.Flags~=nil then table.insert(entry.printProps,"Flags:"..tostring(enchantment.Flags)) end
            if enchantment.StatKey~=nil then table.insert(entry.printProps,"StatKey:"..tostring(enchantment.StatKey)) end
            if enchantment.StatValue~=nil then table.insert(entry.printProps,"StatValue:"..tostring(enchantment.StatValue)) end
            if enchantment.SpellSetId~=nil then table.insert(entry.printProps,"SpellSetId:"..tostring(enchantment.SpellSetId)) end
            if enchantment.Effect~=nil then table.insert(entry.printProps,"Effect:"..tostring(enchantment.Effect)) end
            if enchantment.ExpiresAt~=nil then table.insert(entry.printProps,"ExpiresAt:"..tostring(enchantment.ExpiresAt)) end
            if enchantment.ClientReceivedAt~=nil then table.insert(entry.printProps,"ClientReceivedAt:"..tostring(enchantment.ClientReceivedAt)) end
            table.insert(entry.printProps,"---------------------")
            if spell.Id~=nil then table.insert(entry.printProps,"Id:"..tostring(spell.Id)) end
            if spell.Name~=nil then table.insert(entry.printProps,"Name:"..tostring(spell.Name)) end
            if spell.Description~=nil then table.insert(entry.printProps,"Description:"..tostring(spell.Description)) end
            if spell.School~=nil then table.insert(entry.printProps,"School:"..tostring(spell.School)) end
            if spell.Icon~=nil then table.insert(entry.printProps,"Icon:"..tostring(spell.Icon)) end
            if spell.Category~=nil then table.insert(entry.printProps,"Category:"..tostring(spell.Category)) end
            if spell.Flags~=nil then table.insert(entry.printProps,"Flags:"..tostring(spell.Flags)) end
            if spell.Power~=nil then table.insert(entry.printProps,"Power:"..tostring(spell.Power)) end
            if spell.SpellEconomyMod~=nil then table.insert(entry.printProps,"SpellEconomyMod:"..tostring(spell.SpellEconomyMod)) end
            if spell.FormulaVersion~=nil then table.insert(entry.printProps,"FormulaVersion:"..tostring(spell.FormulaVersion)) end
            if spell.ComponentLoss~=nil then table.insert(entry.printProps,"ComponentLoss:"..tostring(spell.ComponentLoss)) end
            if spell.MetaSpellType~=nil then table.insert(entry.printProps,"MetaSpellType:"..tostring(spell.MetaSpellType)) end
            if spell.MetaSpellId~=nil then table.insert(entry.printProps,"MetaSpellId:"..tostring(spell.MetaSpellId)) end
            if spell.Duration~=nil then table.insert(entry.printProps,"Duration:"..tostring(spell.Duration)) end
            if spell.CasterEffect~=nil then table.insert(entry.printProps,"CasterEffect:"..tostring(spell.CasterEffect)) end
            if spell.TargetEffect~=nil then table.insert(entry.printProps,"TargetEffect:"..tostring(spell.TargetEffect)) end
            if spell.FizzleEffect~=nil then table.insert(entry.printProps,"FizzleEffect:"..tostring(spell.FizzleEffect)) end
            if spell.RecoveryInterval~=nil then table.insert(entry.printProps,"RecoveryInterval:"..tostring(spell.RecoveryInterval)) end
            if spell.RecoveryAmount~=nil then table.insert(entry.printProps,"RecoveryAmount:"..tostring(spell.RecoveryAmount)) end
            if spell.DisplayOrder~=nil then table.insert(entry.printProps,"DisplayOrder:"..tostring(spell.DisplayOrder)) end
            if spell.Level~=nil then table.insert(entry.printProps,"Level:"..tostring(spell.Level)) end
            if spell.StatModType~=nil then table.insert(entry.printProps,"StatModType:"..tostring(spell.StatModType)) end
            if spell.StatModKey~=nil then table.insert(entry.printProps,"StatModKey:"..tostring(spell.StatModKey)) end
            if spell.StatModVal~=nil then table.insert(entry.printProps,"StatModVal:"..tostring(spell.StatModVal)) end
            if spell.StatModAttribute~=nil then table.insert(entry.printProps,"StatModAttribute:"..tostring(spell.StatModAttribute)) end
            if spell.StatModVital~=nil then table.insert(entry.printProps,"StatModVital:"..tostring(spell.StatModVital)) end
            if spell.StatModSkill~=nil then table.insert(entry.printProps,"StatModSkill:"..tostring(spell.StatModSkill)) end
            if spell.StatModIntProp~=nil then table.insert(entry.printProps,"StatModIntProp:"..tostring(spell.StatModIntProp)) end
            if spell.StatModFloatProp~=nil then table.insert(entry.printProps,"StatModFloatProp:"..tostring(spell.StatModFloatProp)) end
            if spell.DamageType~=nil then table.insert(entry.printProps,"DamageType:"..tostring(spell.DamageType)) end
            if spell.BaseIntensity~=nil then table.insert(entry.printProps,"BaseIntensity:"..tostring(spell.BaseIntensity)) end
            if spell.Variance~=nil then table.insert(entry.printProps,"Variance:"..tostring(spell.Variance)) end
            if spell.WeenieClassId~=nil then table.insert(entry.printProps,"WeenieClassId:"..tostring(spell.WeenieClassId)) end
            if spell.VitalDamageType~=nil then table.insert(entry.printProps,"VitalDamageType:"..tostring(spell.VitalDamageType)) end
            if spell.Boost~=nil then table.insert(entry.printProps,"Boost:"..tostring(spell.Boost)) end
            if spell.BoostVariance~=nil then table.insert(entry.printProps,"BoostVariance:"..tostring(spell.BoostVariance)) end
            if spell.Source~=nil then table.insert(entry.printProps,"Source:"..tostring(spell.Source)) end
            if spell.Proportion~=nil then table.insert(entry.printProps,"Proportion:"..tostring(spell.Proportion)) end
            if spell.LossPercent~=nil then table.insert(entry.printProps,"LossPercent:"..tostring(spell.LossPercent)) end
            if spell.SourceLoss~=nil then table.insert(entry.printProps,"SourceLoss:"..tostring(spell.SourceLoss)) end
          end--]]
