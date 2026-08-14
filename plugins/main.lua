require "import"
import "android.widget.*"
import "com.androlua.*"
import "android.content.Context"
import "android.view.KeyEvent"
import "android.os.Handler"
import "java.lang.Runnable"

math.randomseed(os.time())

local context = activity or service
local contador = 0
local miHandler = Handler()

-- Caracteres válidos para generar IDs de Google Drive realistas
local caracteres = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"

-- Función interna rápida para generar un ID único de archivo
local function generarIdDrive()
  local id = ""
  for i = 1, 20 do
    local rand = math.random(1, #caracteres)
    id = id .. caracteres:sub(rand, rand)
  end
  return id
end

function enviarMensajeBomba(veces)
  -- Lote de 25 disparos instantáneos por ciclo
  local lote = 25
  local ejecutados = 0
  
  while contador < veces and ejecutados < lote do
    -- Construye un enlace de Google Drive único
    local idFalso = generarIdDrive()
    local enlaceDrive = "https://drive.google.com/file/d/1" .. idFalso .. "/view?usp=sharing"
    
    -- Inyección y envío automático
    service.setText(enlaceDrive)
    if not service.click({{"Enviar"}}) then
      service.click({{"Send"}})
    end
    
    contador = contador + 1
    ejecutados = ejecutados + 1
  end
  
  -- Si faltan enlaces por mandar, el Handler reactiva el hilo al instante
  if contador < veces then
    miHandler.post(Runnable{
      run = function()
        enviarMensajeBomba(veces)
      end
    })
  else
    contador = 0
    service.speak("Envío masivo de enlaces de Drive finalizado")
  end
end

-- Interfaz gráfica
layout = {
  LinearLayout,
  orientation = LinearLayout.VERTICAL,
  {
    TextView,
    text = "Spammeador Enlaces Drive",
    textSize = "20sp",
    gravity = 17,
    padding = "16dp",
  },
  {
    EditText,
    id = "vecesInput",
    hint = "Cantidad de enlaces a enviar",
    inputType = "number",
    layout_width = "fill",
    padding = "16dp",
  },
  {
    Button,
    text = "Enviar",
    onClick = function(view)
      local veces = tonumber(vecesInput.Text)
      if veces == nil or veces <= 0 then
        service.speak("Ingresa una cantidad válida")
      else
        dlg.dismiss()
        contador = 0
        enviarMensajeBomba(veces)
      end
    end,
    layout_width = "wrap_content",
    gravity = 5,
  },
  {
    Button,
    text = "Salir",
    onClick = function(view)
      dlg.dismiss()
    end,
    layout_width = "wrap_content",
    gravity = 5,
  },
}

dlg = LuaDialog(service)
dlg.View = loadlayout(layout)
dlg.show()

function onKeyDown(code, event)
  if code == KeyEvent.KEYCODE_BACK then
    dlg.dismiss()
    return true
  end
  return true
end