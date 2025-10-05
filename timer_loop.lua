-- scheduler.lua
-- Esegue /run/timer_script.lua ogni n secondi, per k volte
-- Uso: scheduler.lua <intervallo_secondi> <ripetizioni>

local args = {...}
local interval = tonumber(args[1])
local repeats = tonumber(args[2])

if not interval then
  term.clear()
  term.setCursorPos(1,1)
  write("Intervallo tra esecuzioni (s): ")
  interval = tonumber(read())
end

if not repeats then
  write("Numero di ripetizioni: ")
  repeats = tonumber(read())
end

if not interval or interval <= 0 or not repeats or repeats <= 0 then
  print("Parametri non validi.")
  return
end

local scriptPath = "/run/timer_script.lua"

-- Controlla che esista
if not fs.exists(scriptPath) then
  print("ERRORE: Script non trovato a " .. scriptPath)
  return
end

print(string.format("Eseguo %s ogni %ds per %d volte", scriptPath, interval, repeats))
print("Premi CTRL+T per interrompere.")

for i = 1, repeats do
  print(string.format("\n[ Esecuzione %d di %d ]", i, repeats))

  -- Avvia lo script figlio
  local ok, err = pcall(function()
    shell.run(scriptPath, tostring(interval)) -- passo l'intervallo come argomento se serve
  end)

  if not ok then
    print("Errore nell'esecuzione: " .. tostring(err))
  end

  if i < repeats then
    print(string.format("Attendo %d secondi prima del prossimo ciclo...", interval))
    sleep(interval)
  end
end

print("\nCiclo completato!")
