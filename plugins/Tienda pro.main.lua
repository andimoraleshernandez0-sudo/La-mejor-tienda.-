require "import"
import "android.widget.*"
import "android.view.*"
import "android.content.*"
import "android.app.*"
import "android.app.AlertDialog"
import "android.view.WindowManager"
import "android.os.Handler"
import "android.os.Looper"
import "java.io.File"
import "java.io.FileOutputStream"
import "java.lang.String"
import "java.lang.Runnable"
import "java.lang.Byte"
import "java.lang.reflect.Array"
import "java.net.URL"
import "java.net.HttpURLConnection"
import "java.io.BufferedReader"
import "java.io.InputStreamReader"
import "org.json.JSONObject"
import "org.json.JSONArray"
import "android.util.Base64"
import "android.net.*"
import "android.graphics.Typeface"

-- CONFIGURACIÓN DEL REPOSITORIO Y RUTAS LOCALES ACTUALIZADA
local CURRENT_VERSION = "1.0.0"
local REPO_USER = "andimoraleshernandez0-sudo"
local REPO_NAME = "La-mejor-tienda.-"
local BRANCH = "main"
local PLUGINS_DIR = "/storage/emulated/0/解说/Plugins/"

local ctx = activity or service
local mainHandler = Handler(Looper.getMainLooper())

local function showToast(msg)
  mainHandler.post(Runnable({ run = function()
    import "android.widget.Toast"
    Toast.makeText(ctx, tostring(msg), Toast.LENGTH_LONG).show()
  end}))
end

-- FUNCIÓN DE CONTACTO WHATSAPP
local function showWhatsAppDialog()
    local listaOpciones = {
        "Principal: +52 432 132 0886\n(Para enviar complementos y soporte)",
        "Alternativo: +52 432 104 9470\n(Para reportar errores y dudas)"
    }
    
    local builder = AlertDialog.Builder(ctx)
        .setTitle("Contacto y Colaboración")
        .setItems(listaOpciones, function(dialog, which)
            if which < 0 then return end
            dialog.dismiss()
            local phone = (which == 0) and "524321320886" or "524321049470"
            local intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://api.whatsapp.com/send?phone=" .. phone))
            if not activity then
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            end
            ctx.startActivity(intent)
        end)
        .setNegativeButton("Cerrar", function(d, w)
            d.dismiss()
        end)
        
    local dialog = builder.create()
    if not activity then
      local window = dialog.getWindow()
      if window then window.setType(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY) end
    end
    dialog.show()
end

-- Declaración anticipada
local openStoreMenu

-- 0. VERIFICACIÓN DE ACTUALIZACIÓN AUTOMÁTICA DEL CLIENTE DE LA TIENDA
local function checkClientUpdate()
  thread(function(currentVer, repoUser, repoName, branch, ctx, mainHandler)
    require "import"
    import "java.net.URL"
    import "java.io.BufferedReader"
    import "java.io.InputStreamReader"
    import "org.json.JSONObject"
    import "android.util.Base64"
    import "java.lang.String"

    pcall(function()
      local versionApiUrl = "https://api.github.com/repos/" .. repoUser .. "/" .. repoName .. "/contents/version.json?t=" .. os.time()
      local url = URL(versionApiUrl)
      local conn = url.openConnection()
      conn.setRequestMethod("GET")
      conn.setUseCaches(false)
      conn.setConnectTimeout(8000)
      conn.setRequestProperty("User-Agent", "JieshuoStoreClient/1.0")
      conn.setRequestProperty("Accept", "application/vnd.github.v3+json")

      if conn.getResponseCode() == 200 then
        local reader = BufferedReader(InputStreamReader(conn.getInputStream(), "UTF-8"))
        local sb = {}
        local line = reader.readLine()
        while line ~= nil do table.insert(sb, line) line = reader.readLine() end
        reader.close()
        local body = table.concat(sb, "\n")

        local obj = JSONObject(body)
        local contentBase64 = obj.optString("content", ""):gsub("%s+", "")
        if #contentBase64 > 0 then
          local decodedBytes = Base64.decode(contentBase64, Base64.DEFAULT)
          local jsonStr = String(decodedBytes, "UTF-8").toString()
          local verObj = JSONObject(jsonStr)

          local remoteVersion = verObj.optString("version", currentVer)
          local updateUrl = verObj.optString("download_url", "")
          local changeLog = verObj.optString("changelog", "Mejoras generales.")

          if remoteVersion ~= currentVer and #updateUrl > 0 then
            mainHandler.post(Runnable({ run = function()
              import "android.app.AlertDialog"
              import "android.view.WindowManager"
              import "android.widget.Toast"

              local builder = AlertDialog.Builder(ctx)
                .setTitle("¡Actualización de Tienda! (" .. remoteVersion .. ")")
                .setMessage("Hay una nueva versión disponible.\n\nNovedades:\n" .. changeLog .. "\n\n¿Deseas actualizar?")
                .setPositiveButton("Actualizar", function()
                  Toast.makeText(ctx, "Descargando actualización...", Toast.LENGTH_SHORT).show()
                  thread(function(dlUrl, ctx)
                    require "import"
                    import "java.net.URL"
                    import "java.io.File"
                    import "java.io.FileOutputStream"
                    import "android.os.Handler"
                    import "android.os.Looper"
                    import "android.widget.Toast"

                    local ok = pcall(function()
                      local conn = URL(dlUrl).openConnection()
                      local is = conn.getInputStream()
                      local targetPath = "/storage/emulated/0/解说/Plugins/App Store /main.lua"
                      local fos = FileOutputStream(File(targetPath))
                      local buffer = java.lang.reflect.Array.newInstance(java.lang.Byte.TYPE, 4096)
                      local len = is.read(buffer)
                      while len > 0 do
                        fos.write(buffer, 0, len)
                        len = is.read(buffer)
                      end
                      fos.close()
                      is.close()
                    end)

                    Handler(Looper.getMainLooper()).post(Runnable({ run = function()
                      if ok then
                        Toast.makeText(ctx, "¡Actualizado con éxito! Recarga el plugin.", Toast.LENGTH_LONG).show()
                      else
                        Toast.makeText(ctx, "Error al actualizar.", Toast.LENGTH_LONG).show()
                      end
                    end}))
                  end, updateUrl, ctx)
                end)
                .setNegativeButton("Más tarde", nil)
              
              local dialog = builder.create()
              if not activity then
                local window = dialog.getWindow()
                if window then window.setType(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY) end
              end
              dialog.show()
            end}))
          end
        end
      end
    end)
  end, CURRENT_VERSION, REPO_USER, REPO_NAME, BRANCH, ctx, mainHandler)
end

-- 1. CONSULTA DE NOTIFICACIONES / MENSAJES DEL ADMINISTRADOR
local function fetchNotificationsAsync(callback)
  showToast("Consultando notificaciones...")

  thread(function(repoUser, repoName, branch, ctx, mainHandler, callback, openStoreMenu)
    require "import"
    import "java.net.URL"
    import "java.net.HttpURLConnection"
    import "java.io.BufferedReader"
    import "java.io.InputStreamReader"
    import "java.lang.Runnable"
    import "android.widget.Toast"
    import "android.util.Base64"
    import "org.json.JSONObject"
    import "org.json.JSONArray"

    local messagesUrl = "https://api.github.com/repos/" .. repoUser .. "/" .. repoName .. "/contents/messages.json?t=" .. os.time()
    local result = { code = -1, body = "" }

    local ok, err = pcall(function()
      local url = URL(messagesUrl)
      local conn = url.openConnection()
      conn.setRequestMethod("GET")
      conn.setUseCaches(false)
      conn.setConnectTimeout(10000)
      conn.setReadTimeout(10000)
      conn.setRequestProperty("User-Agent", "JieshuoStoreClient/1.0")
      conn.setRequestProperty("Accept", "application/vnd.github.v3+json")
      conn.setRequestProperty("Cache-Control", "no-cache, no-store, must-revalidate")

      result.code = conn.getResponseCode()
      if result.code == 200 then
        local reader = BufferedReader(InputStreamReader(conn.getInputStream(), "UTF-8"))
        local sb = {}
        local line = reader.readLine()
        while line ~= nil do table.insert(sb, line) line = reader.readLine() end
        reader.close()
        result.body = table.concat(sb, "\n")
      end
    end)

    mainHandler.post(Runnable({ run = function()
      if ok and result.code == 200 then
        local parseOk, jsonDecoded = pcall(function()
          local obj = JSONObject(result.body)
          local contentBase64 = obj.optString("content", ""):gsub("%s+", "")
          if #contentBase64 > 0 then
            local decodedBytes = Base64.decode(contentBase64, Base64.DEFAULT)
            return String(decodedBytes, "UTF-8").toString()
          end
          return "[]"
        end)
        if parseOk and jsonDecoded then
          callback(jsonDecoded)
        else
          callback("[]")
        end
      else
        Toast.makeText(ctx, "No hay notificaciones disponibles.", Toast.LENGTH_SHORT).show()
        openStoreMenu(false)
      end
    end}))
  end, REPO_USER, REPO_NAME, BRANCH, ctx, mainHandler, callback, openStoreMenu)
end

function openNotificationsMenu(showOnlyNotInstalled)
  fetchNotificationsAsync(function(jsonRaw)
    import "android.app.AlertDialog"
    local parseOk, msgArray = pcall(function() return JSONArray(jsonRaw) end)

    if not parseOk or not msgArray or msgArray.length() == 0 then
      showToast("No hay mensajes o avisos en este momento.")
      openStoreMenu(showOnlyNotInstalled)
      return
    end

    local displayTitles = {}
    local msgDetails = {}

    for i = 0, msgArray.length() - 1 do
      local item = msgArray.getJSONObject(i)
      local title = item.optString("title", "Mensaje sin título")
      local text = item.optString("text", "")
      local date = item.optString("date", "")

      table.insert(displayTitles, title .. " (" .. date .. ")")
      table.insert(msgDetails, { title = title, text = text, date = date })
    end

    local builder = AlertDialog.Builder(ctx)
    builder.setTitle("Notificaciones (" .. #displayTitles .. ")")
    builder.setItems(displayTitles, function(d, w)
      if w < 0 then return end
      d.dismiss()
      local selected = msgDetails[w + 1]

      local msgBuilder = AlertDialog.Builder(ctx)
      msgBuilder.setTitle(selected.title)
      msgBuilder.setMessage("Fecha: " .. selected.date .. "\n\n" .. selected.text)
      msgBuilder.setPositiveButton("Volver a Notificaciones", function()
        openNotificationsMenu(showOnlyNotInstalled)
      end)
      msgBuilder.setNegativeButton("Volver a Tienda", function()
        openStoreMenu(showOnlyNotInstalled)
      end)
      
      local msgDialog = msgBuilder.create()
      if not activity then
        local window = msgDialog.getWindow()
        if window then window.setType(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY) end
      end
      msgDialog.show()
    end)

    builder.setNegativeButton("Volver a Tienda", function(d, w)
      d.dismiss()
      openStoreMenu(showOnlyNotInstalled)
    end)

    local dialog = builder.create()
    if not activity then
      local window = dialog.getWindow()
      if window then window.setType(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY) end
    end
    dialog.show()
  end)
end

-- 2. DESCARGA E INSTALACIÓN DE PLUGINS
local function downloadAndInstallPlugin(downloadUrl, fileName, showOnlyNotInstalled)
  showToast("Descargando " .. fileName .. "...")

  thread(function(downloadUrl, fileName, pluginsDir, ctx, mainHandler, showOnlyNotInstalled, openStoreMenu)
    require "import"
    import "java.net.URL"
    import "java.net.HttpURLConnection"
    import "java.io.File"
    import "java.io.FileOutputStream"
    import "java.lang.Runnable"
    import "java.lang.Byte"
    import "java.lang.reflect.Array"
    import "android.widget.Toast"
    import "android.app.AlertDialog"

    local ok, err = pcall(function()
      local url = URL(downloadUrl)
      local conn = url.openConnection()
      conn.setRequestMethod("GET")
      conn.setInstanceFollowRedirects(true)
      conn.setUseCaches(false)
      conn.setConnectTimeout(15000)
      conn.setReadTimeout(15000)
      conn.setRequestProperty("User-Agent", "JieshuoStoreClient/1.0")

      if conn.getResponseCode() == 200 then
        local dir = File(pluginsDir)
        if not dir.exists() then dir.mkdirs() end

        local destFile = File(pluginsDir .. fileName)
        local inputStream = conn.getInputStream()
        local outputStream = FileOutputStream(destFile)

        local buffer = Array.newInstance(Byte.TYPE, 4096)
        local bytesRead = inputStream.read(buffer)

        while bytesRead ~= -1 do
          outputStream.write(buffer, 0, bytesRead)
          bytesRead = inputStream.read(buffer)
        end

        outputStream.flush()
        outputStream.close()
        inputStream.close()

        mainHandler.post(Runnable({ run = function()
          Toast.makeText(ctx, "¡Plugin '" .. fileName .. "' instalado!", Toast.LENGTH_LONG).show()
        end}))
      else
        mainHandler.post(Runnable({ run = function()
          Toast.makeText(ctx, "Error al descargar (HTTP " .. conn.getResponseCode() .. ")", Toast.LENGTH_LONG).show()
        end}))
      end
    end)

    if not ok then
      mainHandler.post(Runnable({ run = function()
        Toast.makeText(ctx, "Error: " .. tostring(err), Toast.LENGTH_LONG).show()
      end}))
    end

    mainHandler.post(Runnable({ run = function()
      openStoreMenu(showOnlyNotInstalled)
    end}))
  end, downloadUrl, fileName, PLUGINS_DIR, ctx, mainHandler, showOnlyNotInstalled, openStoreMenu)
end

-- 3. CARGA DEL CATÁLOGO DE PLUGINS
local function fetchCatalogAsync(callback)
  showToast("Cargando catálogo...")

  thread(function(repoUser, repoName, branch, ctx, mainHandler, callback)
    require "import"
    import "java.net.URL"
    import "java.net.HttpURLConnection"
    import "java.io.BufferedReader"
    import "java.io.InputStreamReader"
    import "java.lang.Runnable"
    import "android.widget.Toast"
    import "android.util.Base64"
    import "org.json.JSONObject"

    local catalogUrl = "https://api.github.com/repos/" .. repoUser .. "/" .. repoName .. "/contents/catalog.json?t=" .. os.time()
    local result = { code = -1, body = "" }

    local ok, err = pcall(function()
      local url = URL(catalogUrl)
      local conn = url.openConnection()
      conn.setRequestMethod("GET")
      conn.setUseCaches(false)
      conn.setConnectTimeout(10000)
      conn.setReadTimeout(10000)
      conn.setRequestProperty("User-Agent", "JieshuoStoreClient/1.0")
      conn.setRequestProperty("Accept", "application/vnd.github.v3+json")
      conn.setRequestProperty("Cache-Control", "no-cache, no-store, must-revalidate")

      result.code = conn.getResponseCode()
      if result.code == 200 then
        local reader = BufferedReader(InputStreamReader(conn.getInputStream(), "UTF-8"))
        local sb = {}
        local line = reader.readLine()
        while line ~= nil do table.insert(sb, line) line = reader.readLine() end
        reader.close()
        result.body = table.concat(sb, "\n")
      end
    end)

    mainHandler.post(Runnable({ run = function()
      if ok and result.code == 200 then
        local parseOk, jsonDecoded = pcall(function()
          local obj = JSONObject(result.body)
          local contentBase64 = obj.optString("content", ""):gsub("%s+", "")
          local decodedBytes = Base64.decode(contentBase64, Base64.DEFAULT)
          return String(decodedBytes, "UTF-8").toString()
        end)
        if parseOk and jsonDecoded then
          callback(jsonDecoded)
        else
          Toast.makeText(ctx, "Error al decodificar el catálogo.", Toast.LENGTH_LONG).show()
        end
      else
        Toast.makeText(ctx, "Error al conectar con la tienda.", Toast.LENGTH_LONG).show()
      end
    end}))
  end, REPO_USER, REPO_NAME, BRANCH, ctx, mainHandler, callback)
end

-- 4. INTERFAZ PRINCIPAL DE LA TIENDA
openStoreMenu = function(showOnlyNotInstalled)
  if showOnlyNotInstalled == nil then showOnlyNotInstalled = false end

  fetchCatalogAsync(function(jsonRaw)
    import "android.app.AlertDialog"
    local parseOk, catalogArray = pcall(function() return JSONArray(jsonRaw) end)

    if not parseOk or not catalogArray then
      showToast("Error al procesar la tienda.")
      return
    end

    local displayList = {}
    local pluginData = {}

    -- OPCIÓN 1: NOTIFICACIONES
    table.insert(displayList, "🔔 Notificaciones y Mensajes")
    table.insert(pluginData, { isNotificationHeader = true })

    -- OPCIÓN 2: CONTACTAR AL ADMINISTRADOR (WHATSAPP)
    table.insert(displayList, "💬 Contactar al Administrador")
    table.insert(pluginData, { isWhatsAppHeader = true })

    -- OPCIONES SIGUIENTES: PLUGINS
    for i = 0, catalogArray.length() - 1 do
      local item = catalogArray.getJSONObject(i)
      local name = item.optString("name", "Plugin sin nombre")
      local version = item.optString("version", "1.0.0")
      local fileName = item.optString("file_name", "")
      local downloadUrl = item.optString("download_url", "")
      local desc = item.optString("description", "Sin descripción")
      local author = item.optString("author", "Anónimo")

      local isInstalled = false
      if #fileName > 0 then
        local localFile = File(PLUGINS_DIR .. fileName)
        if localFile.exists() then isInstalled = true end
      end

      local evaluateItem = true
      if showOnlyNotInstalled and isInstalled then evaluateItem = false end

      if evaluateItem then
        local label = name .. " v" .. version
        if isInstalled then label = label .. " [Instalado]" end

        table.insert(displayList, label)
        table.insert(pluginData, {
          isNotificationHeader = false,
          isWhatsAppHeader = false,
          name = name,
          version = version,
          fileName = fileName,
          downloadUrl = downloadUrl,
          desc = desc,
          author = author,
          isInstalled = isInstalled
        })
      end
    end

    local builder = AlertDialog.Builder(ctx)
    local modoTexto = showOnlyNotInstalled and "Solo No Instalados" or "Todos"
    builder.setTitle("Tienda - " .. modoTexto)

    builder.setItems(displayList, function(d, w)
      if w < 0 then return end
      
      -- CERRAMOS EL MENÚ PRINCIPAL AL SELECCIONAR CUALQUIER OPCIÓN PARA EVITAR QUE QUEDE EN SEGUNDO PLANO
      d.dismiss()
      
      local selected = pluginData[w + 1]
      if not selected then return end

      if selected.isNotificationHeader then
        openNotificationsMenu(showOnlyNotInstalled)
      elseif selected.isWhatsAppHeader then
        showWhatsAppDialog()
      else
        import "android.widget.*"
        import "android.view.*"

        local scroll = ScrollView(ctx)
        local contentLayout = LinearLayout(ctx)
        contentLayout.setOrientation(LinearLayout.VERTICAL)
        contentLayout.setPadding(30, 20, 30, 20)

        -- 1. COMPLEMENTO
        local tvName = TextView(ctx)
        tvName.setText("📦 " .. selected.name .. " (v" .. selected.version .. ")")
        tvName.setTextSize(18)
        tvName.setTypeface(nil, Typeface.BOLD)
        contentLayout.addView(tvName)

        local tvStatus = TextView(ctx)
        tvStatus.setText("Estado: " .. (selected.isInstalled and "Instalado" or "No instalado"))
        tvStatus.setTextSize(12)
        tvStatus.setPadding(0, 4, 0, 16)
        contentLayout.addView(tvStatus)

        -- 2. DESCRIPCIÓN
        local tvDescTitle = TextView(ctx)
        tvDescTitle.setText("Descripción:")
        tvDescTitle.setTypeface(nil, Typeface.BOLD)
        contentLayout.addView(tvDescTitle)

        local tvDesc = TextView(ctx)
        tvDesc.setText(selected.desc)
        tvDesc.setTextSize(14)
        tvDesc.setPadding(0, 4, 0, 20)
        contentLayout.addView(tvDesc)

        -- 3. AUTOR
        local tvAuthor = TextView(ctx)
        tvAuthor.setText("Autor: " .. selected.author)
        tvAuthor.setTextSize(14)
        tvAuthor.setTypeface(nil, Typeface.BOLD)
        tvAuthor.setPadding(0, 0, 0, 24)
        contentLayout.addView(tvAuthor)

        -- 4. BOTONES
        local btnInstall = Button(ctx)
        local btnText = selected.isInstalled and "Reinstalar / Actualizar" or "Descargar e Instalar"
        btnInstall.setText(btnText)
        btnInstall.setOnClickListener(function()
          downloadAndInstallPlugin(selected.downloadUrl, selected.fileName, showOnlyNotInstalled)
        end)
        contentLayout.addView(btnInstall)

        if selected.isInstalled then
          local btnDelete = Button(ctx)
          btnDelete.setText("Eliminar Local")
          btnDelete.setOnClickListener(function()
            local f = File(PLUGINS_DIR .. selected.fileName)
            if f.exists() and f.delete() then
              showToast("Plugin eliminado localmente.")
            else
              showToast("No se pudo eliminar.")
            end
            detailsDialog.dismiss()
            openStoreMenu(showOnlyNotInstalled)
          end)
          contentLayout.addView(btnDelete)
        end

        local btnBack = Button(ctx)
        btnBack.setText("Volver")

        scroll.addView(contentLayout)

        local detailsBuilder = AlertDialog.Builder(ctx)
        detailsBuilder.setTitle("Detalles del Complemento")
        detailsBuilder.setView(scroll)
        
        -- CAPTURAMOS LA REFERENCIA EXACTA DEL DIÁLOGO DE DETALLES
        detailsDialog = detailsBuilder.create()
        if not activity then
          local window = detailsDialog.getWindow()
          if window then window.setType(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY) end
        end
        detailsDialog.show()

        btnBack.setOnClickListener(function()
          detailsDialog.dismiss()
          openStoreMenu(showOnlyNotInstalled)
        end)
      end
    end)

    local toggleText = showOnlyNotInstalled and "Ver Todos" or "Solo No Instalados"
    builder.setNeutralButton(toggleText, function(d, w)
      d.dismiss()
      openStoreMenu(not showOnlyNotInstalled)
    end)

    builder.setNegativeButton("Cerrar", function(d, w)
      -- CIERRE TOTAL LIMPIO DE LA TIENDA
      d.dismiss()
    end)

    local dialog = builder.create()
    if not activity then
      local window = dialog.getWindow()
      if window then window.setType(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY) end
    end
    dialog.show()
  end)
end

-- EJECUCIÓN INICIAL
checkClientUpdate()
openStoreMenu(false)