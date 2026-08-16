require "import"
import "android.view.View"
import "android.widget.*"
import "com.androlua.*"
import "android.speech.tts.TextToSpeech"
import "android.content.Context"
import "android.app.AlertDialog"
import "android.content.DialogInterface"
import "java.util.Locale"
import "org.json.JSONObject"
import "org.json.JSONArray"
import "java.io.File"

local ttsEngine = nil

-- Inicialización segura del motor TTS
ttsEngine = TextToSpeech(service, TextToSpeech.OnInitListener{
  onInit = function(status)
    if status == TextToSpeech.SUCCESS then
      pcall(function()
        local locLatino = Locale("es", "MX")
        ttsEngine.setLanguage(locLatino)
      end)
    end
  end
})

local layout = {
  LinearLayout,
  orientation = "vertical",
  padding = "16dp",
  { TextView, text = "Generador de Podcasts Autónomos", textSize = "18sp", gravity = 17, padding = "8dp" },
  {
    ScrollView,
    layout_width = "match_parent",
    layout_height = "0dp",
    layout_weight = 1,
    {
      LinearLayout,
      orientation = "vertical",
      { TextView, text = "Título del episodio:", textSize = "14sp" },
      { EditText, id = "txtTitulo", hint = "Ejemplo: Enigmas de la Ciencia", layout_width = "match_parent", singleLine = true },
      
      { TextView, text = "Tema a desarrollar:", textSize = "14sp", top = "6dp" },
      { EditText, id = "txtTema", hint = "Ejemplo: La Exploración Espacial", layout_width = "match_parent", singleLine = true },

      -- Configuración Locutor 1
      { TextView, text = "--- Locutor 1 ---", textSize = "15sp", top = "12dp" },
      { EditText, id = "txtHostA", text = "Carlos", hint = "Nombre del Locutor 1", layout_width = "match_parent", singleLine = true },
      { TextView, id = "lblTonoA", text = "Tono Locutor 1: 1.00x", textSize = "12sp", top = "4dp" },
      { SeekBar, id = "skTonoA", layout_width = "match_parent", max = 150, progress = 50 },
      { TextView, id = "lblVelA", text = "Velocidad Locutor 1: 1.00x", textSize = "12sp", top = "4dp" },
      { SeekBar, id = "skVelA", layout_width = "match_parent", max = 150, progress = 50 },

      -- Configuración Locutor 2
      { TextView, text = "--- Locutor 2 ---", textSize = "15sp", top = "12dp" },
      { EditText, id = "txtHostB", text = "Sofía", hint = "Nombre del Locutor 2", layout_width = "match_parent", singleLine = true },
      { TextView, id = "lblTonoB", text = "Tono Locutor 2: 1.25x", textSize = "12sp", top = "4dp" },
      { SeekBar, id = "skTonoB", layout_width = "match_parent", max = 150, progress = 75 },
      { TextView, id = "lblVelB", text = "Velocidad Locutor 2: 1.05x", textSize = "12sp", top = "4dp" },
      { SeekBar, id = "skVelB", layout_width = "match_parent", max = 150, progress = 55 },
    }
  },
  { Button, id = "btnGenerarYProcesar", text = "Generar y Producir Podcast", layout_width = "match_parent", top = "10dp" },
  { Button, id = "btnExportar", text = "Guardar Episodio Independiente (JSON)", layout_width = "match_parent", top = "6dp" },
  { Button, id = "btnCargarJSON", text = "Cargar Podcast (JSON)", layout_width = "match_parent", top = "6dp" },
  { Button, id = "btnCerrar", text = "Detener y Cerrar", layout_width = "match_parent", top = "6dp" },
}

local ids = {}
local dlg = LuaDialog(service)
dlg.View = loadlayout(layout, ids)

local window = dlg.getWindow()
if window then window.setType(2032) end

local function calcularValorTTS(progreso)
  local p = tonumber(progreso) or 50
  return 0.5 + (p / 100.0)
end

ids.skTonoA.setOnSeekBarChangeListener(SeekBar.OnSeekBarChangeListener{
  onProgressChanged = function(sb, prog, user)
    ids.lblTonoA.setText(string.format("Tono Locutor 1: %.2fx", calcularValorTTS(prog)))
  end
})

ids.skVelA.setOnSeekBarChangeListener(SeekBar.OnSeekBarChangeListener{
  onProgressChanged = function(sb, prog, user)
    ids.lblVelA.setText(string.format("Velocidad Locutor 1: %.2fx", calcularValorTTS(prog)))
  end
})

ids.skTonoB.setOnSeekBarChangeListener(SeekBar.OnSeekBarChangeListener{
  onProgressChanged = function(sb, prog, user)
    ids.lblTonoB.setText(string.format("Tono Locutor 2: %.2fx", calcularValorTTS(prog)))
  end
})

ids.skVelB.setOnSeekBarChangeListener(SeekBar.OnSeekBarChangeListener{
  onProgressChanged = function(sb, prog, user)
    ids.lblVelB.setText(string.format("Velocidad Locutor 2: %.2fx", calcularValorTTS(prog)))
  end
})

-- Garantiza devolver siempre una tabla Lua válida
local function construirPodcastIndependiente(titulo, tema, hostA, hostB, tonoA, velA, tonoB, velB)
  local t = (type(titulo) == "string" and titulo ~= "") and titulo or "Sin Título"
  local tm = (type(tema) == "string" and tema ~= "") and tema or "General"
  local hA = (type(hostA) == "string" and hostA ~= "") and hostA or "Locutor 1"
  local hB = (type(hostB) == "string" and hostB ~= "") and hostB or "Locutor 2"

  return {
    {locutor = hA, tono = tonumber(tonoA) or 1.0, velocidad = tonumber(velA) or 1.0, texto = "¡Hola a todos! Bienvenidos a este nuevo episodio titulado: " .. t .. "."},
    {locutor = hB, tono = tonumber(tonoB) or 1.25, velocidad = tonumber(velB) or 1.05, texto = "¡Así es, " .. hA .. "! Hoy tenemos un tema impresionante preparado para ustedes: " .. tm .. "."},
    {locutor = hA, tono = tonumber(tonoA) or 1.0, velocidad = tonumber(velA) or 1.0, texto = "Analizando el trasfondo de " .. tm .. ", encontramos datos fascinantes que cambian nuestra perspectiva."},
    {locutor = hB, tono = tonumber(tonoB) or 1.25, velocidad = tonumber(velB) or 1.05, texto = "Definitivamente. Muchas gracias por acompañarnos en este resumen en español latino. ¡Hasta la próxima!"}
  }
end

local function reproducirEpisodio(guion)
  if type(guion) ~= "table" or #guion == 0 then
    service.speak("Error: No se recibió una lista de diálogos válida.")
    return
  end

  service.speak("Iniciando reproducción del podcast...")
  
  thread(function()
    local listaGuion = guion
    if type(listaGuion) == "table" then
      for _, linea in ipairs(listaGuion) do
        if ttsEngine and type(linea) == "table" then
          pcall(function()
            ttsEngine.setPitch(linea.tono or 1.0)
            ttsEngine.setSpeechRate(linea.velocidad or 1.0)
            
            local frase = (linea.locutor or "Locutor") .. " dice: " .. (linea.texto or "")
            ttsEngine.speak(frase, TextToSpeech.QUEUE_FLUSH, nil, "PodcastUtterance")
          end)
          
          local factorVelocidad = (linea.velocidad and tonumber(linea.velocidad) > 0) and tonumber(linea.velocidad) or 1.0
          local textoLen = type(linea.texto) == "string" and #linea.texto or 10
          local tiempoEspera = math.ceil((textoLen * 65) / factorVelocidad) + 800
          Thread.sleep(tiempoEspera)
        end
      end
    end
    
    if ttsEngine then
      pcall(function()
        ttsEngine.setPitch(1.0)
        ttsEngine.setSpeechRate(1.0)
      end)
    end
    service.speak("Reproducción finalizada.")
  end)
end

local function exportarEpisodioJSON(titulo, tema, guion)
  if type(guion) ~= "table" or #guion == 0 then
    service.speak("Error: No hay datos para exportar.")
    return
  end

  pcall(function()
    local tL = (type(titulo) == "string" and titulo ~= "") and titulo or "podcast_exportado"
    local path = service.getFilesDir().getAbsolutePath() .. "/" .. tL:gsub("%s+", "_") .. ".json"
    local jsonRoot = JSONObject()
    jsonRoot.put("titulo", tL)
    jsonRoot.put("tema", tema or "")
    jsonRoot.put("idioma", "es-LATAM")
    
    local jsonArr = JSONArray()
    for _, item in ipairs(guion) do
      if type(item) == "table" then
        local obj = JSONObject()
        obj.put("locutor", item.locutor or "Locutor")
        obj.put("tono", item.tono or 1.0)
        obj.put("velocidad", item.velocidad or 1.0)
        obj.put("texto", item.texto or "")
        jsonArr.put(obj)
      end
    end
    jsonRoot.put("dialogo", jsonArr)
    
    local f = io.open(path, "w")
    if f then
      f:write(jsonRoot.toString(2))
      f:close()
      service.speak("Episodio guardado exitosamente.")
    end
  end)
end

local function cargarYReproducirJSON(filePath)
  pcall(function()
    local file = File(filePath)
    if not file.exists() then
      service.speak("El archivo no existe.")
      return
    end

    local f = io.open(filePath, "r")
    if not f then
      service.speak("No se pudo abrir el archivo JSON.")
      return
    end

    local contenido = f:read("*a")
    f:close()

    if not contenido or contenido == "" then
      service.speak("El archivo JSON está vacío.")
      return
    end

    local jsonRoot = JSONObject(contenido)
    local jsonArr = jsonRoot.optJSONArray("dialogo")
    
    if not jsonArr then
      service.speak("El archivo no contiene la clave de diálogos.")
      return
    end

    local guion = {}
    for i = 0, jsonArr.length() - 1 do
      local item = jsonArr.optJSONObject(i)
      if item then
        table.insert(guion, {
          locutor = item.optString("locutor", "Locutor"),
          tono = item.optDouble("tono", 1.0),
          velocidad = item.optDouble("velocidad", 1.0),
          texto = item.optString("texto", "")
        })
      end
    end

    local titulo = jsonRoot.optString("titulo", "Podcast")
    service.speak("Podcast cargado: " .. titulo)
    reproducirEpisodio(guion)
  end)
end

local function mostrarListaPodcastsGuardados()
  local dirPath = service.getFilesDir().getAbsolutePath()
  local dir = File(dirPath)
  local archivos = dir.listFiles()
  local listaNombres = {}
  local listaRutas = {}

  if archivos then
    for i = 0, #archivos - 1 do
      local f = archivos[i]
      if f and f.isFile() and f.getName():endsWith(".json") then
        table.insert(listaNombres, f.getName())
        table.insert(listaRutas, f.getAbsolutePath())
      end
    end
  end

  if #listaNombres == 0 then
    service.speak("No se encontraron episodios JSON guardados.")
    return
  end

  local builder = AlertDialog.Builder(service)
  builder.setTitle("Podcasts Guardados")
  local adapter = ArrayAdapter(service, android.R.layout.simple_list_item_1, listaNombres)

  builder.setAdapter(adapter, DialogInterface.OnClickListener{
    onClick = function(dialog, which)
      local rutaSeleccionada = listaRutas[which + 1]
      if rutaSeleccionada then
        cargarYReproducirJSON(rutaSeleccionada)
      end
    end
  })
  builder.setNegativeButton("Cancelar", nil)

  local alert = builder.create()
  local win = alert.getWindow()
  if win then win.setType(2032) end
  alert.show()
end

ids.btnGenerarYProcesar.setOnClickListener(View.OnClickListener{
  onClick = function(v)
    local titulo = ids.txtTitulo.getText().toString():match("^%s*(.-)%s*$")
    local tema = ids.txtTema.getText().toString():match("^%s*(.-)%s*$")
    local hostA = ids.txtHostA.getText().toString():match("^%s*(.-)%s*$")
    local hostB = ids.txtHostB.getText().toString():match("^%s*(.-)%s*$")
    
    if titulo == "" or tema == "" then
      service.speak("Ingresa un título y un tema válidos.")
      return
    end

    local tonoA = calcularValorTTS(ids.skTonoA.getProgress())
    local velA = calcularValorTTS(ids.skVelA.getProgress())
    local tonoB = calcularValorTTS(ids.skTonoB.getProgress())
    local velB = calcularValorTTS(ids.skVelB.getProgress())
    
    local guion = construirPodcastIndependiente(titulo, tema, hostA, hostB, tonoA, velA, tonoB, velB)
    reproducirEpisodio(guion)
  end
})

ids.btnExportar.setOnClickListener(View.OnClickListener{
  onClick = function(v)
    local titulo = ids.txtTitulo.getText().toString():match("^%s*(.-)%s*$")
    local tema = ids.txtTema.getText().toString():match("^%s*(.-)%s*$")
    local hostA = ids.txtHostA.getText().toString():match("^%s*(.-)%s*$")
    local hostB = ids.txtHostB.getText().toString():match("^%s*(.-)%s*$")
    
    if titulo == "" or tema == "" then
      service.speak("Escribe un título y tema para exportar el episodio.")
      return
    end

    local tonoA = calcularValorTTS(ids.skTonoA.getProgress())
    local velA = calcularValorTTS(ids.skVelA.getProgress())
    local tonoB = calcularValorTTS(ids.skTonoB.getProgress())
    local velB = calcularValorTTS(ids.skVelB.getProgress())
    
    local guion = construirPodcastIndependiente(titulo, tema, hostA, hostB, tonoA, velA, tonoB, velB)
    exportarEpisodioJSON(titulo, tema, guion)
  end
})

ids.btnCargarJSON.setOnClickListener(View.OnClickListener{
  onClick = function(v)
    mostrarListaPodcastsGuardados()
  end
})

ids.btnCerrar.setOnClickListener(View.OnClickListener{
  onClick = function(v)
    pcall(function()
      if ttsEngine then ttsEngine.stop() end
    end)
    dlg.dismiss()
  end
})

dlg.show()