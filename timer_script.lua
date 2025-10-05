-- timer.lua
-- Timer a n secondi con barra di caricamento colorata su monitor (se presente)
-- e impulso redstone sul lato "back".
-- Uso: timer.lua <secondi>
-- Se non passi l'argomento verrà chiesto a runtime.

local args = {...}
local seconds = tonumber(args[1])

-- input se non fornito
if not seconds then
  term.clear()
  term.setCursorPos(1,1)
  write("Timer (secondi): ")
  seconds = tonumber(read())
end

if not seconds or seconds <= 0 then
  print("Numero di secondi non valido. Esco.")
  return
end

-- Assicuriamoci che l'output redstone sia spento all'inizio
pcall(function() redstone.setOutput("back", false) end)

-- trova un monitor attaccato (se presente)
local function findMonitor()
  local sides = {"top","bottom","left","right","front","back"}
  for _, side in ipairs(sides) do
    if peripheral.getType(side) == "monitor" then
      return peripheral.wrap(side), side
    end
  end
  return nil, nil
end

local mon, monSide = findMonitor()

-- palette di colori (rainbow)
local colorsList = {
  colors.red, colors.orange, colors.yellow, colors.lime, colors.green,
  colors.cyan, colors.lightBlue, colors.blue, colors.purple, colors.magenta
}

-- ora con precisione: usa os.epoch se disponibile, altrimenti os.clock
local function hasEpoch()
  return type(os.epoch) == "function"
end
local function now()
  if hasEpoch() then return os.epoch("ms")/1000 end
  return os.clock()
end

-- disegna la barra sul monitor (mon must be peripheral.wrap result)
local function drawMonitor(mon, total, remaining, progress, shift)
  local w,h = mon.getSize()
  mon.setBackgroundColor(colors.black)
  mon.clear()
  mon.setTextColor(colors.white)
  mon.setCursorPos(1,1)
  local title = string.format("Timer: %ds", math.ceil(remaining))
  mon.write(title)
  local perc = math.floor(progress * 100)
  local percStr = string.format("%3d%%", perc)
  mon.setCursorPos(math.max(1, w - #percStr + 1),1)
  mon.write(percStr)

  local barY = math.min(math.max(2, math.floor(h/2)), h-1)
  local barX = 3
  local barWidth = w - 6
  if barWidth < 4 then barWidth = math.max(1, w-2) end
  local filled = math.floor(progress * barWidth + 0.5)

  for x = 1, barWidth do
    mon.setCursorPos(barX + x - 1, barY)
    if x <= filled then
      local col = colorsList[((x + shift - 1) % #colorsList) + 1]
      mon.setBackgroundColor(col)
      mon.write(" ")
    else
      mon.setBackgroundColor(colors.gray)
      mon.write(" ")
    end
  end

  mon.setBackgroundColor(colors.black)
  mon.setTextColor(colors.white)
  mon.setCursorPos(1, h)
  mon.write(string.format("Rimanenti: %0.1fs  ", math.max(0, remaining)))
  mon.setBackgroundColor(colors.black)
end

-- fallback su terminale (semplice barra testuale)
local function drawTerminal(total, remaining, progress, shift)
  local perc = math.floor(progress * 100)
  term.clear()
  term.setCursorPos(1,1)
  print(string.format("Timer: %0.1fs / %ds", math.max(0, remaining), total))
  local w, h = term.getSize()
  local barWidth = math.max(10, w - 10)
  local filled = math.floor(progress * barWidth + 0.5)
  local line = "[" .. string.rep("=", filled) .. string.rep(" ", barWidth - filled) .. "] " .. perc .. "%"
  print(line)
end

-- loop principale (aggiorna la barra fino a scadenza)
local start = now()
local updateInterval = 0.08  -- aggiornamento ogni ~80ms (regolabile)
local colorShift = 0
while true do
  local elapsed = now() - start
  if elapsed >= seconds then break end
  local remaining = seconds - elapsed
  local progress = math.max(0, math.min(1, elapsed / seconds))
  if mon then
    pcall(drawMonitor, mon, seconds, remaining, progress, colorShift)
  else
    pcall(drawTerminal, seconds, remaining, progress, colorShift)
  end
  colorShift = colorShift + 1
  os.sleep(updateInterval)
end

-- disegna finale (barra piena)
if mon then
  pcall(drawMonitor, mon, seconds, 0, 1, colorShift) -- progress = 1
  os.sleep(0.05)
else
  drawTerminal(seconds, 0, 1, colorShift)
end

-- impulso redstone sul retro
-- durata impulso ~0.18s (modificabile)
pcall(function()
  redstone.setOutput("back", true)
  os.sleep(0.18)
  redstone.setOutput("back", false)
end)

print("Fatto!")
