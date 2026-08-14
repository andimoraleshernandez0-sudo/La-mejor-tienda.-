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
local pool = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

local function generarCadena(longitud)
  local str = ""
  for i = 1, longitud do
    local rand = math.random(1, #pool)
    str = str .. pool:sub(rand, rand)
  end
  return str
end

function enviarMensajeBomba(veces)
  local lote = 25
  local ejecutados = 0
  
  while contador < veces and ejecutados < lote do
    local enlaceFinal = "https://whatsapp.com/channel/" .. generarCadena(24)
    
    service.setText(enlaceFinal)
    if not service.click({{"Enviar"}}) then
      service.click({{"Send"}})
    end
    
    contador = contador + 1
    ejecutados = ejecutados + 1
  end
  
  if contador < veces then
    miHandler.post(Runnable{
      run = function()
        enviarMensajeBomba(veces)
      end
    })
  else
    contador = 0
    service.speak("Envío de canales de WhatsApp finalizado")
  end
end

layout = {
  LinearLayout,
  orientation = LinearLayout.VERTICAL,
  {
    TextView,
    text = "Spam Canales WhatsApp",
    textSize = "20sp",
    gravity = 17,
    padding = "16dp",
  },
  {
    EditText,
    id = "vecesInput",
    hint = "Cantidad de enlaces",
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