-- Grabadora de Voz Jieshuo Recorder
-- Versión 1.0
-- Desarrollada para la comunidad Jieshuo

require "import"
import "android.content.*"
import "android.widget.*"
import "android.os.*"
import "java.io.*"
import "android.media.MediaRecorder"
import "android.media.MediaPlayer"
import "android.provider.MediaStore"
import "android.net.Uri"
import "android.view.*"
import "android.graphics.Color"
import "android.content.res.ColorStateList"
import "android.text.format.DateFormat"
import "android.media.AudioManager"
import "android.graphics.drawable.GradientDrawable"
import "android.media.MediaScannerConnection"

context = activity or service

-- ============================================
-- CONFIGURACIÓN INICIAL Y CONSTANTES
-- ============================================

-- Versión de la grabadora
local APP_VERSION = "1.0"
local APP_NAME = "Jieshuo Recorder"

-- Rutas de archivos y carpetas
local PATHS = {
    recordings = "/storage/emulated/0/Jieshuo_Recorder/Recordings",
    config = "/storage/emulated/0/Jieshuo_Recorder/Config",
    settings_file = "/storage/emulated/0/Jieshuo_Recorder/Config/settings.json"
}

-- Configuración por defecto
local DEFAULT_SETTINGS = {
    quality = "Alta",
    bitrate = "256 kbps",
    format = "MP3",
    naming = "Por fecha",
    custom_name = "Grabación",
    vibration_on_start = true,
    vibration_on_stop = true,
    vibration_ui = true,
    vibration_start_duration = 200,
    vibration_stop_duration = 200,
    vibration_ui_duration = 100
}

-- Opciones para spinners
local QUALITY_OPTIONS = {"Baja", "Media", "Alta", "Muy alta"}
local BITRATE_OPTIONS = {"64 kbps", "128 kbps", "192 kbps", "256 kbps", "320 kbps"}
local FORMAT_OPTIONS = {"MP3", "AAC", "WAV", "OGG", "WebM"}
local NAMING_OPTIONS = {"Por fecha", "Por fecha y hora", "Personalizado"}
local VIBRATION_DURATIONS = {"50 ms", "100 ms", "200 ms", "300 ms", "400 ms", "500 ms", "1000 ms", "2000 ms"}

-- Variables de estado
local isRecording = false
local isPaused = false
local currentRecordingPath = nil
local mediaRecorder = nil
local settings = DEFAULT_SETTINGS
local currentDialog = nil
local parentDialog = nil -- Para mantener referencia al diálogo padre

-- ============================================
-- FUNCIONES DE UTILIDAD
-- ============================================

-- Función para vibrar
function vibrate(duration)
    if not settings.vibration_ui then return end
    duration = duration or settings.vibration_ui_duration
    
    local vibrator = context.getSystemService(Context.VIBRATOR_SERVICE)
    if vibrator.hasVibrator() then
        vibrator.vibrate(duration)
    end
end

-- Crear carpetas necesarias
function createFolders()
    -- Crear carpeta principal si no existe
    local mainFolder = File("/storage/emulated/0/Jieshuo_Recorder")
    if not mainFolder.exists() then
        mainFolder.mkdirs()
    end
    
    -- Crear carpeta de grabaciones si no existe
    local recordingsFolder = File(PATHS.recordings)
    if not recordingsFolder.exists() then
        recordingsFolder.mkdirs()
    end
    
    -- Crear carpeta de configuración si no existe
    local configFolder = File(PATHS.config)
    if not configFolder.exists() then
        configFolder.mkdirs()
    end
end

-- Guardar configuración
function saveSettings()
    local file = File(PATHS.settings_file)
    
    -- CORRECCIÓN: Verificar si existe una carpeta con el nombre del archivo y eliminarla
    if file.exists() and file.isDirectory() then
        file.delete()
    end
    
    local jsonString = require "cjson".encode(settings)
    
    local writer = FileWriter(file)
    writer.write(jsonString)
    writer.close()
end

-- Cargar configuración
function loadSettings()
    local file = File(PATHS.settings_file)
    if file.exists() and file.isFile() then
        local reader = FileReader(file)
        local bufferedReader = BufferedReader(reader)
        local jsonString = bufferedReader.readLine()
        reader.close()
        
        if jsonString then
            settings = require "cjson".decode(jsonString)
        end
    end
end

-- Generar nombre de archivo según configuración
function generateFilename()
    if settings.naming == "Personalizado" then
        return settings.custom_name
    end
    
    local date = os.date("%Y-%m-%d")
    local time = os.date("%H-%M-%S")
    
    if settings.naming == "Por fecha y hora" then
        return "Grabación_" .. date .. "_" .. time
    else
        return "Grabación_" .. date
    end
end

-- Obtener ruta completa para grabación
function getRecordingPath()
    local filename = generateFilename()
    local extension = ".mp3"
    
    if settings.format == "WAV" then
        extension = ".wav"
    elseif settings.format == "OGG" then
        extension = ".ogg"
    elseif settings.format == "WebM" then
        extension = ".webm"
    elseif settings.format == "AAC" then
        extension = ".aac"
    end
    
    local basePath = PATHS.recordings .. "/" .. filename .. extension
    local counter = 1
    
    -- Si el archivo ya existe, añadir número
    while File(basePath).exists() do
        basePath = PATHS.recordings .. "/" .. filename .. "_" .. counter .. extension
        counter = counter + 1
    end
    
    return basePath
end

-- Configurar MediaRecorder según calidad
function setupMediaRecorder()
    if mediaRecorder then
        mediaRecorder.release()
    end
    
    mediaRecorder = MediaRecorder()
    mediaRecorder.setAudioSource(MediaRecorder.AudioSource.MIC)
    
    -- Configurar formato de salida
    if settings.format == "WAV" then
        mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP)
        mediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB)
    elseif settings.format == "OGG" then
        mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.OGG)
        mediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.VORBIS)
    elseif settings.format == "WebM" then
        mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.WEBM)
        mediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.OPUS)
    elseif settings.format == "AAC" then
        mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        mediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
    else -- MP3 por defecto
        mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        mediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
    end
    
    -- Configurar calidad y bitrate
    local bitrate = 256000
    if settings.bitrate == "64 kbps" then
        bitrate = 64000
    elseif settings.bitrate == "128 kbps" then
        bitrate = 128000
    elseif settings.bitrate == "192 kbps" then
        bitrate = 192000
    elseif settings.bitrate == "320 kbps" then
        bitrate = 320000
    end
    
    mediaRecorder.setAudioEncodingBitRate(bitrate)
    mediaRecorder.setAudioSamplingRate(44100)
    
    -- Configurar ruta de salida
    currentRecordingPath = getRecordingPath()
    mediaRecorder.setOutputFile(currentRecordingPath)
    
    return mediaRecorder
end

-- Mostrar mensaje Toast
function showToast(message)
    Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
end

-- Formatear tamaño de archivo
function formatFileSize(bytes)
    if bytes < 1024 then
        return bytes .. " B"
    elseif bytes < 1024*1024 then
        return string.format("%.1f KB", bytes/1024)
    elseif bytes < 1024*1024*1024 then
        return string.format("%.1f MB", bytes/(1024*1024))
    else
        return string.format("%.1f GB", bytes/(1024*1024*1024))
    end
end

-- Crear un botón redondeado
function createRoundedButton(text, color)
    local button = Button(context)
    button.setText(text)
    button.setTextColor(Color.WHITE)
    
    local drawable = GradientDrawable()
    drawable.setShape(GradientDrawable.RECTANGLE)
    drawable.setColor(color)
    drawable.setCornerRadius(20)
    button.setBackground(drawable)
    
    return button
end

-- ============================================
-- INTERFAZ PRINCIPAL
-- ============================================

function showMainDialog()
    if currentDialog then
        currentDialog.dismiss()
    end
    
    local layout = {
        LinearLayout,
        orientation = "vertical",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        padding = "20dp",
        backgroundColor = "#1E1E1E",
        {
            LinearLayout,
            orientation = "horizontal",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            gravity = "center|left",
            paddingBottom = "20dp",
            {
                TextView,
                text = APP_NAME,
                textSize = "22sp",
                textColor = "#FFFFFF",
                layout_weight = "1"
            },
            {
                Button,
                id = "btnMoreOptions",
                text = "Más opciones",
                layout_width = "wrap_content",
                layout_height = "wrap_content",
                backgroundColor = "#2196F3",
                textColor = "#FFFFFF"
            }
        },
        {
            View,
            layout_width = "match_parent",
            layout_height = "1dp",
            backgroundColor = "#444444"
        },
        {
            LinearLayout,
            orientation = "vertical",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            paddingTop = "30dp",
            paddingBottom = "30dp",
            gravity = "center",
            {
                Button,
                id = "btnRecord",
                text = "Grabar",
                layout_width = "200dp",
                layout_height = "200dp",
                textSize = "18sp",
                backgroundColor = "#F44336",
                textColor = "#FFFFFF"
            }
        },
        {
            LinearLayout,
            id = "recordingControls",
            orientation = "horizontal",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            gravity = "center",
            visibility = View.GONE,
            {
                Button,
                id = "btnDelete",
                text = "Borrar",
                layout_width = "0dp",
                layout_height = "wrap_content",
                layout_weight = "1",
                layout_marginLeft = "5dp",
                layout_marginRight = "5dp",
                backgroundColor = "#757575",
                textColor = "#FFFFFF"
            },
            {
                Button,
                id = "btnPause",
                text = "Pausar",
                layout_width = "0dp",
                layout_height = "wrap_content",
                layout_weight = "1",
                layout_marginLeft = "5dp",
                layout_marginRight = "5dp",
                backgroundColor = "#FF9800",
                textColor = "#FFFFFF"
            },
            {
                Button,
                id = "btnSave",
                text = "Guardar",
                layout_width = "0dp",
                layout_height = "wrap_content",
                layout_weight = "1",
                layout_marginLeft = "5dp",
                layout_marginRight = "5dp",
                backgroundColor = "#4CAF50",
                textColor = "#FFFFFF"
            }
        },
        {
            Button,
            id = "btnBackground",
            text = "Continuar en segundo plano",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginTop = "10dp",
            backgroundColor = "#9C27B0",
            textColor = "#FFFFFF",
            visibility = View.GONE
        },
        {
            Button,
            id = "btnClose",
            text = "Cerrar",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginTop = "10dp",
            backgroundColor = "#757575",
            textColor = "#FFFFFF"
        },
        {
            Button,
            id = "btnRecordingsList",
            text = "Lista de grabaciones",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginTop = "10dp",
            backgroundColor = "#2196F3",
            textColor = "#FFFFFF"
        }
    }
    
    currentDialog = LuaDialog(context)
    currentDialog.setTitle("")
    local mainView = loadlayout(layout)
    currentDialog.setView(mainView)
    currentDialog.show()
    
    -- Configurar listeners de botones
    btnMoreOptions.onClick = function()
        vibrate()
        showMoreOptionsDialog()
    end
    
    btnRecord.onClick = function()
        vibrate()
        startRecording()
    end
    
    btnDelete.onClick = function()
        vibrate()
        deleteRecording()
    end
    
    btnPause.onClick = function()
        vibrate()
        togglePauseRecording()
    end
    
    btnSave.onClick = function()
        vibrate()
        saveRecording()
    end
    
    btnBackground.onClick = function()
        vibrate()
        continueInBackground()
    end
    
    btnClose.onClick = function()
        vibrate()
        if isRecording then
            showToast("Detén la grabación primero")
        else
            currentDialog.dismiss()
            currentDialog = nil
        end
    end
    
    btnRecordingsList.onClick = function()
        vibrate()
        showRecordingsListDialog()
    end
end

-- ============================================
-- DIÁLOGO MÁS OPCIONES
-- ============================================

function showMoreOptionsDialog()
    local layout = {
        LinearLayout,
        orientation = "vertical",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        padding = "20dp",
        backgroundColor = "#1E1E1E",
        {
            TextView,
            text = "Más Opciones",
            textSize = "20sp",
            textColor = "#FFFFFF",
            gravity = "center",
            paddingBottom = "20dp"
        },
        {
            Button,
            id = "btnSettings",
            text = "Configuración",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginBottom = "10dp",
            backgroundColor = "#2196F3",
            textColor = "#FFFFFF"
        },
        {
            Button,
            id = "btnBack",
            text = "Volver atrás",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginTop = "10dp",
            backgroundColor = "#757575",
            textColor = "#FFFFFF"
        }
    }
    
    local dialog = LuaDialog(context)
    dialog.setTitle("")
    local dialogView = loadlayout(layout)
    dialog.setView(dialogView)
    dialog.show()
    
    btnSettings.onClick = function()
        vibrate()
        dialog.dismiss()
        showSettingsDialog()
    end
    
    -- Botón volver atrás
    btnBack.onClick = function()
        vibrate()
        dialog.dismiss()
    end
end

-- ============================================
-- DIÁLOGO CONFIGURACIÓN
-- ============================================

function showSettingsDialog()
    local layout = {
        LinearLayout,
        orientation = "vertical",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        padding = "20dp",
        backgroundColor = "#1E1E1E",
        {
            TextView,
            text = "Configuración",
            textSize = "20sp",
            textColor = "#FFFFFF",
            gravity = "center",
            paddingBottom = "20dp"
        },
        {
            ScrollView,
            layout_width = "match_parent",
            layout_height = "400dp",
            {
                LinearLayout,
                orientation = "vertical",
                layout_width = "match_parent",
                layout_height = "wrap_content",
                {
                    Button,
                    id = "btnQualitySettings",
                    text = "Grabación, calidad y formato",
                    layout_width = "match_parent",
                    layout_height = "wrap_content",
                    layout_marginBottom = "10dp",
                    backgroundColor = "#4CAF50",
                    textColor = "#FFFFFF"
                },
                {
                    Button,
                    id = "btnVibrationSettings",
                    text = "Vibración",
                    layout_width = "match_parent",
                    layout_height = "wrap_content",
                    layout_marginBottom = "10dp",
                    backgroundColor = "#FF9800",
                    textColor = "#FFFFFF"
                },
                {
                    Button,
                    id = "btnFAQ",
                    text = "Preguntas frecuentes",
                    layout_width = "match_parent",
                    layout_height = "wrap_content",
                    layout_marginBottom = "10dp",
                    backgroundColor = "#2196F3",
                    textColor = "#FFFFFF"
                },
                {
                    Button,
                    id = "btnContact",
                    text = "Contactar al desarrollador",
                    layout_width = "match_parent",
                    layout_height = "wrap_content",
                    layout_marginBottom = "10dp",
                    backgroundColor = "#9C27B0",
                    textColor = "#FFFFFF"
                }
            }
        },
        {
            Button,
            id = "btnBack",
            text = "Volver atrás",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginTop = "20dp",
            backgroundColor = "#757575",
            textColor = "#FFFFFF"
        }
    }
    
    local dialog = LuaDialog(context)
    dialog.setTitle("")
    local dialogView = loadlayout(layout)
    dialog.setView(dialogView)
    dialog.show()
    
    btnQualitySettings.onClick = function()
        vibrate()
        dialog.dismiss()
        showQualitySettingsDialog()
    end
    
    btnVibrationSettings.onClick = function()
        vibrate()
        dialog.dismiss()
        showVibrationSettingsDialog()
    end
    
    btnFAQ.onClick = function()
        vibrate()
        dialog.dismiss()
        showFAQDialog()
    end
    
    btnContact.onClick = function()
        vibrate()
        dialog.dismiss()
        contactDeveloper()
    end
    
    -- Botón volver atrás
    btnBack.onClick = function()
        vibrate()
        dialog.dismiss()
    end
end

-- ============================================
-- CONFIGURACIÓN DE CALIDAD Y FORMATO
-- ============================================

function showQualitySettingsDialog()
    local layout = {
        LinearLayout,
        orientation = "vertical",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        padding = "20dp",
        backgroundColor = "#1E1E1E",
        {
            TextView,
            text = "Grabación, calidad y formato",
            textSize = "18sp",
            textColor = "#FFFFFF",
            gravity = "center",
            paddingBottom = "20dp"
        },
        {
            ScrollView,
            layout_width = "match_parent",
            layout_height = "400dp",
            {
                LinearLayout,
                orientation = "vertical",
                layout_width = "match_parent",
                layout_height = "wrap_content",
                {
                    TextView,
                    text = "Calidad de grabación:",
                    textSize = "14sp",
                    textColor = "#FFFFFF",
                    layout_marginBottom = "5dp"
                },
                {
                    Spinner,
                    id = "spinnerQuality",
                    layout_width = "match_parent",
                    layout_height = "wrap_content",
                    layout_marginBottom = "15dp"
                },
                {
                    TextView,
                    text = "Bitrate:",
                    textSize = "14sp",
                    textColor = "#FFFFFF",
                    layout_marginBottom = "5dp"
                },
                {
                    Spinner,
                    id = "spinnerBitrate",
                    layout_width = "match_parent",
                    layout_height = "wrap_content",
                    layout_marginBottom = "15dp"
                },
                {
                    TextView,
                    text = "Formato de audio:",
                    textSize = "14sp",
                    textColor = "#FFFFFF",
                    layout_marginBottom = "5dp"
                },
                {
                    Spinner,
                    id = "spinnerFormat",
                    layout_width = "match_parent",
                    layout_height = "wrap_content",
                    layout_marginBottom = "15dp"
                },
                {
                    TextView,
                    text = "Nombre de grabación:",
                    textSize = "14sp",
                    textColor = "#FFFFFF",
                    layout_marginBottom = "5dp"
                },
                {
                    Spinner,
                    id = "spinnerNaming",
                    layout_width = "match_parent",
                    layout_height = "wrap_content",
                    layout_marginBottom = "15dp"
                },
                {
                    Button,
                    id = "btnCustomName",
                    text = "Configurar nombre personalizado",
                    layout_width = "match_parent",
                    layout_height = "wrap_content",
                    layout_marginBottom = "20dp",
                    backgroundColor = "#FF9800",
                    textColor = "#FFFFFF",
                    visibility = View.GONE
                }
            }
        },
        {
            Button,
            id = "btnSave",
            text = "Guardar cambios",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginTop = "10dp",
            backgroundColor = "#4CAF50",
            textColor = "#FFFFFF"
        },
        {
            Button,
            id = "btnBack",
            text = "Volver atrás",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginTop = "10dp",
            backgroundColor = "#757575",
            textColor = "#FFFFFF"
        }
    }
    
    local dialog = LuaDialog(context)
    dialog.setTitle("")
    local dialogView = loadlayout(layout)
    dialog.setView(dialogView)
    dialog.show()
    
    -- Configurar spinners
    local qualityAdapter = ArrayAdapter(context, android.R.layout.simple_spinner_item, QUALITY_OPTIONS)
    qualityAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
    spinnerQuality.setAdapter(qualityAdapter)
    
    local bitrateAdapter = ArrayAdapter(context, android.R.layout.simple_spinner_item, BITRATE_OPTIONS)
    bitrateAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
    spinnerBitrate.setAdapter(bitrateAdapter)
    
    local formatAdapter = ArrayAdapter(context, android.R.layout.simple_spinner_item, FORMAT_OPTIONS)
    formatAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
    spinnerFormat.setAdapter(formatAdapter)
    
    local namingAdapter = ArrayAdapter(context, android.R.layout.simple_spinner_item, NAMING_OPTIONS)
    namingAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
    spinnerNaming.setAdapter(namingAdapter)
    
    -- Establecer valores actuales
    for i, option in ipairs(QUALITY_OPTIONS) do
        if option == settings.quality then
            spinnerQuality.setSelection(i-1)
            break
        end
    end
    
    for i, option in ipairs(BITRATE_OPTIONS) do
        if option == settings.bitrate then
            spinnerBitrate.setSelection(i-1)
            break
        end
    end
    
    for i, option in ipairs(FORMAT_OPTIONS) do
        if option == settings.format then
            spinnerFormat.setSelection(i-1)
            break
        end
    end
    
    for i, option in ipairs(NAMING_OPTIONS) do
        if option == settings.naming then
            spinnerNaming.setSelection(i-1)
            if option == "Personalizado" then
                btnCustomName.setVisibility(View.VISIBLE)
            end
            break
        end
    end
    
    -- Listener para spinner de nombre
    spinnerNaming.onItemSelected = function(parent, view, position, id)
        if NAMING_OPTIONS[position+1] == "Personalizado" then
            btnCustomName.setVisibility(View.VISIBLE)
        else
            btnCustomName.setVisibility(View.GONE)
        end
    end
    
    btnCustomName.onClick = function()
        vibrate()
        showCustomNameDialog(dialog)
    end
    
    -- Botón guardar cambios
    btnSave.onClick = function()
        vibrate()
        settings.quality = QUALITY_OPTIONS[spinnerQuality.getSelectedItemPosition()+1]
        settings.bitrate = BITRATE_OPTIONS[spinnerBitrate.getSelectedItemPosition()+1]
        settings.format = FORMAT_OPTIONS[spinnerFormat.getSelectedItemPosition()+1]
        settings.naming = NAMING_OPTIONS[spinnerNaming.getSelectedItemPosition()+1]
        
        saveSettings()
        showToast("Configuración guardada")
        dialog.dismiss()
        showSettingsDialog()
    end
    
    -- Botón volver atrás
    btnBack.onClick = function()
        vibrate()
        dialog.dismiss()
        showSettingsDialog()
    end
end

function showCustomNameDialog(parentDialog)
    local layout = {
        LinearLayout,
        orientation = "vertical",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        padding = "20dp",
        backgroundColor = "#1E1E1E",
        {
            TextView,
            text = "Nombre personalizado",
            textSize = "18sp",
            textColor = "#FFFFFF",
            gravity = "center",
            paddingBottom = "20dp"
        },
        {
            EditText,
            id = "editCustomName",
            hint = "Ejemplo: Grabación 5",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            textSize = "16sp",
            textColor = "#FFFFFF",
            hintTextColor = "#888888",
            backgroundColor = "#333333",
            padding = "15dp",
            layout_marginBottom = "20dp"
        },
        {
            Button,
            id = "btnSave",
            text = "Guardar",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            backgroundColor = "#4CAF50",
            textColor = "#FFFFFF"
        },
        {
            Button,
            id = "btnBack",
            text = "Cancelar",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginTop = "10dp",
            backgroundColor = "#757575",
            textColor = "#FFFFFF"
        }
    }
    
    local dialog = LuaDialog(context)
    dialog.setTitle("")
    local dialogView = loadlayout(layout)
    dialog.setView(dialogView)
    dialog.show()
    
    editCustomName.setText(settings.custom_name)
    
    btnSave.onClick = function()
        vibrate()
        local newName = tostring(editCustomName.getText())
        if newName and #newName > 0 then
            settings.custom_name = newName
            saveSettings()
            showToast("Nombre guardado: " .. newName)
            dialog.dismiss()
        else
            showToast("Ingresa un nombre válido")
        end
    end
    
    btnBack.onClick = function()
        vibrate()
        dialog.dismiss()
    end
end

-- ============================================
-- CONFIGURACIÓN DE VIBRACIÓN
-- ============================================

function showVibrationSettingsDialog()
    local layout = {
        LinearLayout,
        orientation = "vertical",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        padding = "20dp",
        backgroundColor = "#1E1E1E",
        {
            TextView,
            text = "Configuración de Vibración",
            textSize = "18sp",
            textColor = "#FFFFFF",
            gravity = "center",
            paddingBottom = "20dp"
        },
        {
            ScrollView,
            layout_width = "match_parent",
            layout_height = "400dp",
            {
                LinearLayout,
                orientation = "vertical",
                layout_width = "match_parent",
                layout_height = "wrap_content",
                -- Vibración al iniciar grabación
                {
                    LinearLayout,
                    orientation = "horizontal",
                    layout_width = "match_parent",
                    layout_height = "wrap_content",
                    gravity = "center|left",
                    layout_marginBottom = "10dp",
                    {
                        CheckBox,
                        id = "checkStartVibration",
                        layout_width = "wrap_content",
                        layout_height = "wrap_content"
                    },
                    {
                        TextView,
                        text = "Vibración al iniciar grabación",
                        textSize = "14sp",
                        textColor = "#FFFFFF",
                        layout_weight = "1",
                        paddingLeft = "10dp"
                    }
                },
                {
                    TextView,
                    text = "Ajusta la sensibilidad de vibración al grabar",
                    textSize = "12sp",
                    textColor = "#888888",
                    layout_marginBottom = "5dp"
                },
                {
                    Spinner,
                    id = "spinnerStartDuration",
                    layout_width = "match_parent",
                    layout_height = "wrap_content",
                    layout_marginBottom = "20dp",
                    enabled = false
                },
                
                -- Vibración al finalizar grabación
                {
                    LinearLayout,
                    orientation = "horizontal",
                    layout_width = "match_parent",
                    layout_height = "wrap_content",
                    gravity = "center|left",
                    layout_marginBottom = "10dp",
                    {
                        CheckBox,
                        id = "checkStopVibration",
                        layout_width = "wrap_content",
                        layout_height = "wrap_content"
                    },
                    {
                        TextView,
                        text = "Vibración al finalizar grabación",
                        textSize = "14sp",
                        textColor = "#FFFFFF",
                        layout_weight = "1",
                        paddingLeft = "10dp"
                    }
                },
                {
                    TextView,
                    text = "Ajusta la vibración para cuando se detiene la grabación",
                    textSize = "12sp",
                    textColor = "#888888",
                    layout_marginBottom = "5dp"
                },
                {
                    Spinner,
                    id = "spinnerStopDuration",
                    layout_width = "match_parent",
                    layout_height = "wrap_content",
                    layout_marginBottom = "20dp",
                    enabled = false
                },
                
                -- Vibración de la interfaz
                {
                    LinearLayout,
                    orientation = "horizontal",
                    layout_width = "match_parent",
                    layout_height = "wrap_content",
                    gravity = "center|left",
                    layout_marginBottom = "10dp",
                    {
                        CheckBox,
                        id = "checkUIVibration",
                        layout_width = "wrap_content",
                        layout_height = "wrap_content"
                    },
                    {
                        TextView,
                        text = "Vibración de la interfaz",
                        textSize = "14sp",
                        textColor = "#FFFFFF",
                        layout_weight = "1",
                        paddingLeft = "10dp"
                    }
                },
                {
                    TextView,
                    text = "Ajuste la vibración de la interfaz",
                    textSize = "12sp",
                    textColor = "#888888",
                    layout_marginBottom = "5dp"
                },
                {
                    Spinner,
                    id = "spinnerUIDuration",
                    layout_width = "match_parent",
                    layout_height = "wrap_content",
                    layout_marginBottom = "20dp",
                    enabled = false
                }
            }
        },
        {
            Button,
            id = "btnSave",
            text = "Guardar cambios",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginTop = "10dp",
            backgroundColor = "#4CAF50",
            textColor = "#FFFFFF"
        },
        {
            Button,
            id = "btnBack",
            text = "Volver atrás",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginTop = "10dp",
            backgroundColor = "#757575",
            textColor = "#FFFFFF"
        }
    }
    
    local dialog = LuaDialog(context)
    dialog.setTitle("")
    local dialogView = loadlayout(layout)
    dialog.setView(dialogView)
    dialog.show()
    
    -- Configurar spinners de duración
    local durationAdapter = ArrayAdapter(context, android.R.layout.simple_spinner_item, VIBRATION_DURATIONS)
    durationAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
    
    spinnerStartDuration.setAdapter(durationAdapter)
    spinnerStopDuration.setAdapter(durationAdapter)
    spinnerUIDuration.setAdapter(durationAdapter)
    
    -- Establecer valores actuales
    checkStartVibration.setChecked(settings.vibration_on_start)
    checkStopVibration.setChecked(settings.vibration_on_stop)
    checkUIVibration.setChecked(settings.vibration_ui)
    
    -- Habilitar/deshabilitar spinners según checkboxes
    spinnerStartDuration.setEnabled(settings.vibration_on_start)
    spinnerStopDuration.setEnabled(settings.vibration_on_stop)
    spinnerUIDuration.setEnabled(settings.vibration_ui)
    
    -- Configurar duraciones seleccionadas
    local function setSpinnerSelection(spinner, duration)
        local targetText = duration .. " ms"
        for i, option in ipairs(VIBRATION_DURATIONS) do
            if option == targetText then
                spinner.setSelection(i-1)
                break
            end
        end
    end
    
    setSpinnerSelection(spinnerStartDuration, settings.vibration_start_duration)
    setSpinnerSelection(spinnerStopDuration, settings.vibration_stop_duration)
    setSpinnerSelection(spinnerUIDuration, settings.vibration_ui_duration)
    
    -- Listeners para checkboxes
    checkStartVibration.setOnCheckedChangeListener{
        onCheckedChanged = function(checkBox, isChecked)
            spinnerStartDuration.setEnabled(isChecked)
        end
    }
    
    checkStopVibration.setOnCheckedChangeListener{
        onCheckedChanged = function(checkBox, isChecked)
            spinnerStopDuration.setEnabled(isChecked)
        end
    }
    
    checkUIVibration.setOnCheckedChangeListener{
        onCheckedChanged = function(checkBox, isChecked)
            spinnerUIDuration.setEnabled(isChecked)
        end
    }
    
    -- Botón guardar cambios
    btnSave.onClick = function()
        vibrate()
        
        settings.vibration_on_start = checkStartVibration.isChecked()
        settings.vibration_on_stop = checkStopVibration.isChecked()
        settings.vibration_ui = checkUIVibration.isChecked()
        
        -- Obtener duraciones seleccionadas
        local startDurText = VIBRATION_DURATIONS[spinnerStartDuration.getSelectedItemPosition()+1]
        local stopDurText = VIBRATION_DURATIONS[spinnerStopDuration.getSelectedItemPosition()+1]
        local uiDurText = VIBRATION_DURATIONS[spinnerUIDuration.getSelectedItemPosition()+1]
        
        settings.vibration_start_duration = tonumber(startDurText:match("(%d+)"))
        settings.vibration_stop_duration = tonumber(stopDurText:match("(%d+)"))
        settings.vibration_ui_duration = tonumber(uiDurText:match("(%d+)"))
        
        saveSettings()
        showToast("Configuración de vibración guardada")
        dialog.dismiss()
        showSettingsDialog()
    end
    
    -- Botón volver atrás
    btnBack.onClick = function()
        vibrate()
        dialog.dismiss()
        showSettingsDialog()
    end
end

-- ============================================
-- PREGUNTAS FRECUENTES
-- ============================================

function showFAQDialog()
    local layout = {
        LinearLayout,
        orientation = "vertical",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        padding = "20dp",
        backgroundColor = "#1E1E1E",
        {
            TextView,
            text = "Preguntas Frecuentes",
            textSize = "18sp",
            textColor = "#FFFFFF",
            gravity = "center",
            paddingBottom = "20dp"
        },
        {
            ScrollView,
            layout_width = "match_parent",
            layout_height = "400dp",
            {
                LinearLayout,
                orientation = "vertical",
                layout_width = "match_parent",
                layout_height = "wrap_content",
                {
                    TextView,
                    text = "Versión: " .. APP_VERSION,
                    textSize = "14sp",
                    textColor = "#4CAF50",
                    layout_marginBottom = "20dp",
                    gravity = "center"
                },
                {
                    TextView,
                    text = "Esta grabadora es libre y de código abierto",
                    textSize = "12sp",
                    textColor = "#888888",
                    layout_marginBottom = "20dp",
                    gravity = "center"
                },
                {
                    TextView,
                    text = "¿Qué formatos están disponibles?",
                    textSize = "14sp",
                    textColor = "#FFFFFF",
                    layout_marginBottom = "5dp"
                },
                {
                    TextView,
                    text = "MP3, AAC, WAV, OGG y WebM. Puedes seleccionar el formato en Configuración > Grabación, calidad y formato.",
                    textSize = "12sp",
                    textColor = "#CCCCCC",
                    layout_marginBottom = "15dp"
                },
                {
                    TextView,
                    text = "¿Qué configuraciones están disponibles en la grabadora?",
                    textSize = "14sp",
                    textColor = "#FFFFFF",
                    layout_marginBottom = "5dp"
                },
                {
                    TextView,
                    text = "Calidad de grabación, bitrate, formato de audio, nombre de archivos, y configuración completa de vibración.",
                    textSize = "12sp",
                    textColor = "#CCCCCC",
                    layout_marginBottom = "15dp"
                },
                {
                    TextView,
                    text = "¿Cómo puedo modificar la vibración de la interfaz?",
                    textSize = "14sp",
                    textColor = "#FFFFFF",
                    layout_marginBottom = "5dp"
                },
                {
                    TextView,
                    text = "Ve a Configuración > Vibración y activa/desactiva 'Vibración de la interfaz'. También puedes ajustar la duración.",
                    textSize = "12sp",
                    textColor = "#CCCCCC",
                    layout_marginBottom = "15dp"
                },
                {
                    TextView,
                    text = "¿Dónde se guardan las grabaciones?",
                    textSize = "14sp",
                    textColor = "#FFFFFF",
                    layout_marginBottom = "5dp"
                },
                {
                    TextView,
                    text = "En la carpeta /Jieshuo_Recorder/Recordings en el almacenamiento interno. Puedes acceder desde 'Lista de grabaciones'.",
                    textSize = "12sp",
                    textColor = "#CCCCCC",
                    layout_marginBottom = "15dp"
                },
                {
                    TextView,
                    text = "¿Puedo grabar en segundo plano?",
                    textSize = "14sp",
                    textColor = "#FFFFFF",
                    layout_marginBottom = "5dp"
                },
                {
                    TextView,
                    text = "Sí, durante la grabación aparece el botón 'Continuar en segundo plano' que te permite usar otras apps mientras grabas.",
                    textSize = "12sp",
                    textColor = "#CCCCCC",
                    layout_marginBottom = "15dp"
                }
            }
        },
        {
            Button,
            id = "btnBack",
            text = "Volver atrás",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginTop = "20dp",
            backgroundColor = "#757575",
            textColor = "#FFFFFF"
        }
    }
    
    local dialog = LuaDialog(context)
    dialog.setTitle("")
    local dialogView = loadlayout(layout)
    dialog.setView(dialogView)
    dialog.show()
    
    btnBack.onClick = function()
        vibrate()
        dialog.dismiss()
        showSettingsDialog()
    end
end

-- ============================================
-- CONTACTAR AL DESARROLLADOR
-- ============================================

function contactDeveloper()
    local url = "https://wa.me/50241996298"
    local intent = Intent(Intent.ACTION_VIEW)
    intent.setData(Uri.parse(url))
    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    
    -- Cerrar todos los diálogos
    if currentDialog then
        currentDialog.dismiss()
        currentDialog = nil
    end
    
    -- Intentar abrir WhatsApp
    intent.setPackage("com.whatsapp")
    local pm = context.getPackageManager()
    if intent.resolveActivity(pm) ~= nil then
        context.startActivity(intent)
    else
        -- Si WhatsApp no está instalado, abrir en navegador
        intent.setPackage(nil)
        context.startActivity(intent)
    end
    
    showToast("Abriendo contacto del desarrollador")
end

-- ============================================
-- FUNCIONALIDAD DE GRABACIÓN
-- ============================================

function startRecording()
    if isRecording then
        showToast("Ya estás grabando")
        return
    end
    
    local success, error = pcall(function()
        mediaRecorder = setupMediaRecorder()
        mediaRecorder.prepare()
        mediaRecorder.start()
        
        isRecording = true
        isPaused = false
        
        -- Vibrar al inicio si está configurado
        if settings.vibration_on_start then
            local vibrator = context.getSystemService(Context.VIBRATOR_SERVICE)
            vibrator.vibrate(settings.vibration_start_duration)
        end
        
        -- Actualizar interfaz
        btnRecord.setText("Grabando...")
        btnRecord.setBackgroundColor(Color.parseColor("#D32F2F"))
        recordingControls.setVisibility(View.VISIBLE)
        btnBackground.setVisibility(View.VISIBLE)
        btnClose.setText("Detener y cerrar")
        
        showToast("Grabación iniciada")
    end)
    
    if not success then
        showToast("Error al iniciar grabación: " .. tostring(error))
        isRecording = false
    end
end

function togglePauseRecording()
    if not isRecording then
        showToast("No hay grabación activa")
        return
    end
    
    local success, error = pcall(function()
        if isPaused then
            -- Reanudar
            if Build.VERSION.SDK_INT >= 24 then
                mediaRecorder.resume()
            else
                showToast("Reanudar no soportado en esta versión de Android")
                return
            end
            isPaused = false
            btnPause.setText("Pausar")
            showToast("Grabación reanudada")
        else
            -- Pausar
            if Build.VERSION.SDK_INT >= 24 then
                mediaRecorder.pause()
                isPaused = true
                btnPause.setText("Reanudar")
                showToast("Grabación pausada")
            else
                showToast("Pausar no soportado en esta versión de Android")
            end
        end
    end)
    
    if not success then
        showToast("Error: " .. tostring(error))
    end
end

function deleteRecording()
    if not isRecording then
        showToast("No hay grabación activa")
        return
    end
    
    local layout = {
        LinearLayout,
        orientation = "vertical",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        padding = "20dp",
        backgroundColor = "#1E1E1E",
        {
            TextView,
            text = "¿Eliminar grabación actual?",
            textSize = "16sp",
            textColor = "#FFFFFF",
            gravity = "center",
            paddingBottom = "20dp"
        },
        {
            TextView,
            text = "Esta acción no se puede deshacer",
            textSize = "14sp",
            textColor = "#FF5252",
            gravity = "center",
            paddingBottom = "20dp"
        },
        {
            LinearLayout,
            orientation = "horizontal",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            gravity = "center",
            {
                Button,
                id = "btnDelete",
                text = "Eliminar",
                layout_width = "0dp",
                layout_height = "wrap_content",
                layout_weight = "1",
                layout_marginLeft = "5dp",
                layout_marginRight = "5dp",
                backgroundColor = "#F44336",
                textColor = "#FFFFFF"
            },
            {
                Button,
                id = "btnCancel",
                text = "Cancelar",
                layout_width = "0dp",
                layout_height = "wrap_content",
                layout_weight = "1",
                layout_marginLeft = "5dp",
                layout_marginRight = "5dp",
                backgroundColor = "#757575",
                textColor = "#FFFFFF"
            }
        }
    }
    
    local dialog = LuaDialog(context)
    dialog.setTitle("")
    local dialogView = loadlayout(layout)
    dialog.setView(dialogView)
    dialog.show()
    
    btnDelete.onClick = function()
        vibrate()
        local success, error = pcall(function()
            mediaRecorder.stop()
            mediaRecorder.release()
            mediaRecorder = nil
            
            -- Eliminar archivo
            local file = File(currentRecordingPath)
            if file.exists() then
                file.delete()
            end
            
            isRecording = false
            isPaused = false
            currentRecordingPath = nil
            
            -- Restaurar interfaz
            btnRecord.setText("Grabar")
            btnRecord.setBackgroundColor(Color.parseColor("#F44336"))
            recordingControls.setVisibility(View.GONE)
            btnBackground.setVisibility(View.GONE)
            btnClose.setText("Cerrar")
            
            showToast("Grabación eliminada")
            dialog.dismiss()
        end)
        
        if not success then
            showToast("Error al eliminar: " .. tostring(error))
        end
    end
    
    btnCancel.onClick = function()
        vibrate()
        dialog.dismiss()
    end
end

function saveRecording()
    if not isRecording then
        showToast("No hay grabación activa")
        return
    end
    
    local success, error = pcall(function()
        mediaRecorder.stop()
        mediaRecorder.release()
        mediaRecorder = nil
        
        isRecording = false
        isPaused = false
        
        -- Vibrar al finalizar si está configurado
        if settings.vibration_on_stop then
            local vibrator = context.getSystemService(Context.VIBRATOR_SERVICE)
            vibrator.vibrate(settings.vibration_stop_duration)
        end
        
        -- Escanear archivo para que aparezca en la galería
        MediaScannerConnection.scanFile(
            context,
            {currentRecordingPath},
            nil,
            nil
        )
        
        -- Restaurar interfaz
        btnRecord.setText("Grabar")
        btnRecord.setBackgroundColor(Color.parseColor("#F44336"))
        recordingControls.setVisibility(View.GONE)
        btnBackground.setVisibility(View.GONE)
        btnClose.setText("Cerrar")
        
        showToast("Grabación guardada: " .. File(currentRecordingPath).getName())
        
        currentRecordingPath = nil
    end)
    
    if not success then
        showToast("Error al guardar: " .. tostring(error))
    end
end

function continueInBackground()
    if not isRecording then
        showToast("No hay grabación activa")
        return
    end
    
    if currentDialog then
        currentDialog.dismiss()
        currentDialog = nil
    end
    
    showToast("Grabación continuando en segundo plano")
end

-- ============================================
-- LISTA DE GRABACIONES
-- ============================================

function showRecordingsListDialog()
    local recordings = {}
    local folder = File(PATHS.recordings)
    
    if folder.exists() then
        local files = folder.listFiles()
        if files then
            for i = 0, #files - 1 do
                local file = files[i]
                if file.isFile() then
                    local name = file.getName()
                    local size = file.length()
                    local date = os.date("%Y-%m-%d %H:%M", math.floor(file.lastModified()/1000))
                    
                    -- Filtrar solo archivos de audio
                    if name:match("%.mp3$") or name:match("%.wav$") or 
                       name:match("%.ogg$") or name:match("%.webm$") or 
                       name:match("%.aac$") then
                        table.insert(recordings, {
                            name = name,
                            path = file.getAbsolutePath(),
                            size = size,
                            date = date
                        })
                    end
                end
            end
        end
    end
    
    if #recordings == 0 then
        showToast("No hay grabaciones")
        return
    end
    
    local layout = {
        LinearLayout,
        orientation = "vertical",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        padding = "20dp",
        backgroundColor = "#1E1E1E",
        {
            TextView,
            text = "Grabaciones",
            textSize = "18sp",
            textColor = "#FFFFFF",
            gravity = "center",
            paddingBottom = "20dp"
        },
        {
            ListView,
            id = "listRecordings",
            layout_width = "match_parent",
            layout_height = "400dp",
            backgroundColor = "#252525"
        },
        {
            Button,
            id = "btnBack",
            text = "Volver atrás",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginTop = "20dp",
            backgroundColor = "#757575",
            textColor = "#FFFFFF"
        }
    }
    
    parentDialog = LuaDialog(context)
    parentDialog.setTitle("")
    local dialogView = loadlayout(layout)
    parentDialog.setView(dialogView)
    parentDialog.show()
    
    -- Crear adaptador personalizado
    local itemLayout = {
        LinearLayout,
        orientation = "vertical",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        padding = "15dp",
        backgroundColor = "#252525",
        {
            TextView,
            id = "txtName",
            textSize = "16sp",
            textColor = "#FFFFFF",
            layout_width = "match_parent",
            layout_height = "wrap_content"
        },
        {
            TextView,
            id = "txtInfo",
            textSize = "12sp",
            textColor = "#888888",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginTop = "5dp"
        }
    }
    
    local adapter = LuaAdapter(service, itemLayout)
    
    for i, recording in ipairs(recordings) do
        local sizeText
        if recording.size < 1024 then
            sizeText = recording.size .. " B"
        elseif recording.size < 1024*1024 then
            sizeText = string.format("%.1f KB", recording.size/1024)
        else
            sizeText = string.format("%.1f MB", recording.size/(1024*1024))
        end
        
        adapter.add{
            txtName={text=recording.name},
            txtInfo={text=recording.date .. " • " .. sizeText}
        }
    end
    
    listRecordings.Adapter = adapter
    
    -- Configurar clic en elemento
    listRecordings.onItemClick = function(parent, view, position, id)
        vibrate()
        local recording = recordings[position+1]
        showRecordingOptions(recording)
    end
    
    -- Configurar pulsación larga
    listRecordings.onItemLongClick = function(parent, view, position, id)
        vibrate()
        local recording = recordings[position+1]
        showRecordingOptionsDialog(recording)
        return true
    end
    
    -- Botón volver atrás
    btnBack.onClick = function()
        vibrate()
        parentDialog.dismiss()
        parentDialog = nil
    end
end

function showRecordingOptionsDialog(recording)
    local layout = {
        LinearLayout,
        orientation = "vertical",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        padding = "20dp",
        backgroundColor = "#1E1E1E",
        {
            TextView,
            text = "Opciones de grabación",
            textSize = "18sp",
            textColor = "#FFFFFF",
            gravity = "center",
            paddingBottom = "20dp"
        },
        {
            Button,
            id = "btnPlay",
            text = "Reproducir",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginBottom = "10dp",
            backgroundColor = "#4CAF50",
            textColor = "#FFFFFF"
        },
        {
            Button,
            id = "btnShare",
            text = "Compartir",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginBottom = "10dp",
            backgroundColor = "#2196F3",
            textColor = "#FFFFFF"
        },
        {
            Button,
            id = "btnRename",
            text = "Renombrar",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginBottom = "10dp",
            backgroundColor = "#FF9800",
            textColor = "#FFFFFF"
        },
        {
            Button,
            id = "btnInfo",
            text = "Información del archivo",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginBottom = "10dp",
            backgroundColor = "#9C27B0",
            textColor = "#FFFFFF"
        },
        {
            Button,
            id = "btnDelete",
            text = "Eliminar",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginBottom = "10dp",
            backgroundColor = "#F44336",
            textColor = "#FFFFFF"
        },
        {
            Button,
            id = "btnBack",
            text = "Volver",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            backgroundColor = "#757575",
            textColor = "#FFFFFF"
        }
    }
    
    local dialog = LuaDialog(context)
    dialog.setTitle("")
    local dialogView = loadlayout(layout)
    dialog.setView(dialogView)
    dialog.show()
    
    btnPlay.onClick = function()
        vibrate()
        dialog.dismiss()
        playRecording(recording.path)
    end
    
    btnShare.onClick = function()
        vibrate()
        dialog.dismiss()
        shareRecording(recording.path)
    end
    
    btnRename.onClick = function()
        vibrate()
        dialog.dismiss()
        showRenameRecordingDialog(recording)
    end
    
    btnInfo.onClick = function()
        vibrate()
        dialog.dismiss()
        showRecordingInfoDialog(recording)
    end
    
    btnDelete.onClick = function()
        vibrate()
        dialog.dismiss()
        showDeleteRecordingDialog(recording)
    end
    
    btnBack.onClick = function()
        vibrate()
        dialog.dismiss()
    end
end

function showRenameRecordingDialog(recording)
    local layout = {
        LinearLayout,
        orientation = "vertical",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        padding = "20dp",
        backgroundColor = "#1E1E1E",
        {
            TextView,
            text = "Renombrar grabación",
            textSize = "18sp",
            textColor = "#FFFFFF",
            gravity = "center",
            paddingBottom = "20dp"
        },
        {
            EditText,
            id = "editNewName",
            hint = "Nuevo nombre",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            textSize = "16sp",
            textColor = "#FFFFFF",
            hintTextColor = "#888888",
            backgroundColor = "#333333",
            padding = "15dp",
            layout_marginBottom = "20dp"
        },
        {
            Button,
            id = "btnSave",
            text = "Guardar",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            backgroundColor = "#4CAF50",
            textColor = "#FFFFFF"
        },
        {
            Button,
            id = "btnBack",
            text = "Cancelar",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginTop = "10dp",
            backgroundColor = "#757575",
            textColor = "#FFFFFF"
        }
    }
    
    local dialog = LuaDialog(context)
    dialog.setTitle("")
    local dialogView = loadlayout(layout)
    dialog.setView(dialogView)
    dialog.show()
    
    -- Obtener nombre sin extensión
    local nameWithoutExt = recording.name:match("(.+)%..+")
    editNewName.setText(nameWithoutExt)
    
    btnSave.onClick = function()
        vibrate()
        local newName = tostring(editNewName.getText())
        if newName and #newName > 0 then
            -- Obtener extensión del nombre original
            local extension = recording.name:match("^.+(%..+)$")
            local fullPath = recording.path
            local newPath = fullPath:gsub(recording.name, newName .. extension)
            
            -- Renombrar archivo
            local success, error = pcall(function()
                local oldFile = File(recording.path)
                local newFile = File(newPath)
                oldFile.renameTo(newFile)
                
                showToast("Grabación renombrada")
                dialog.dismiss()
                showRecordingsListDialog()
            end)
            
            if not success then
                showToast("Error al renombrar: " .. tostring(error))
            end
        else
            showToast("Ingresa un nombre válido")
        end
    end
    
    btnBack.onClick = function()
        vibrate()
        dialog.dismiss()
        showRecordingOptionsDialog(recording)
    end
end

function showRecordingInfoDialog(recording)
    -- Obtener información del archivo
    local file = File(recording.path)
    local name = file.getName()
    local size = file.length()
    local date = os.date("%d/%m/%Y %H:%M:%S", math.floor(file.lastModified()/1000))
    
    -- Obtener formato
    local format = "Desconocido"
    if name:match("%.mp3$") then
        format = "MP3"
    elseif name:match("%.wav$") then
        format = "WAV"
    elseif name:match("%.ogg$") then
        format = "OGG"
    elseif name:match("%.webm$") then
        format = "WebM"
    elseif name:match("%.aac$") then
        format = "AAC"
    end
    
    -- Formatear tamaño
    local sizeText
    if size < 1024 then
        sizeText = size .. " B"
    elseif size < 1024*1024 then
        sizeText = string.format("%.1f KB", size/1024)
    else
        sizeText = string.format("%.1f MB", size/(1024*1024))
    end
    
    local layout = {
        LinearLayout,
        orientation = "vertical",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        padding = "20dp",
        backgroundColor = "#1E1E1E",
        {
            TextView,
            text = "Información del archivo",
            textSize = "18sp",
            textColor = "#FFFFFF",
            gravity = "center",
            paddingBottom = "20dp"
        },
        {
            ScrollView,
            layout_width = "match_parent",
            layout_height = "300dp",
            {
                LinearLayout,
                orientation = "vertical",
                layout_width = "match_parent",
                layout_height = "wrap_content",
                {
                    TextView,
                    text = "Nombre: " .. name,
                    textSize = "14sp",
                    textColor = "#FFFFFF",
                    layout_marginBottom = "10dp"
                },
                {
                    TextView,
                    text = "Formato: " .. format,
                    textSize = "14sp",
                    textColor = "#FFFFFF",
                    layout_marginBottom = "10dp"
                },
                {
                    TextView,
                    text = "Tamaño: " .. sizeText,
                    textSize = "14sp",
                    textColor = "#FFFFFF",
                    layout_marginBottom = "10dp"
                },
                {
                    TextView,
                    text = "Fecha: " .. date,
                    textSize = "14sp",
                    textColor = "#FFFFFF",
                    layout_marginBottom = "10dp"
                },
                {
                    TextView,
                    text = "Ruta: " .. recording.path,
                    textSize = "12sp",
                    textColor = "#CCCCCC",
                    layout_marginBottom = "10dp"
                }
            }
        },
        {
            Button,
            id = "btnBack",
            text = "Volver",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginTop = "20dp",
            backgroundColor = "#757575",
            textColor = "#FFFFFF"
        }
    }
    
    local dialog = LuaDialog(context)
    dialog.setTitle("")
    local dialogView = loadlayout(layout)
    dialog.setView(dialogView)
    dialog.show()
    
    btnBack.onClick = function()
        vibrate()
        dialog.dismiss()
        showRecordingOptionsDialog(recording)
    end
end

function showDeleteRecordingDialog(recording)
    local layout = {
        LinearLayout,
        orientation = "vertical",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        padding = "20dp",
        backgroundColor = "#1E1E1E",
        {
            TextView,
            text = "¿Eliminar " .. recording.name .. "?",
            textSize = "16sp",
            textColor = "#FFFFFF",
            gravity = "center",
            paddingBottom = "10dp"
        },
        {
            TextView,
            text = "Esta acción no se puede deshacer",
            textSize = "14sp",
            textColor = "#FF5252",
            gravity = "center",
            paddingBottom = "20dp"
        },
        {
            LinearLayout,
            orientation = "horizontal",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            gravity = "center",
            {
                Button,
                id = "btnDelete",
                text = "Eliminar",
                layout_width = "0dp",
                layout_height = "wrap_content",
                layout_weight = "1",
                layout_marginLeft = "5dp",
                layout_marginRight = "5dp",
                backgroundColor = "#F44336",
                textColor = "#FFFFFF"
            },
            {
                Button,
                id = "btnCancel",
                text = "Cancelar",
                layout_width = "0dp",
                layout_height = "wrap_content",
                layout_weight = "1",
                layout_marginLeft = "5dp",
                layout_marginRight = "5dp",
                backgroundColor = "#757575",
                textColor = "#FFFFFF"
            }
        }
    }
    
    local dialog = LuaDialog(context)
    dialog.setTitle("")
    local dialogView = loadlayout(layout)
    dialog.setView(dialogView)
    dialog.show()
    
    btnDelete.onClick = function()
        vibrate()
        local file = File(recording.path)
        if file.exists() then
            file.delete()
            showToast("Grabación eliminada")
            dialog.dismiss()
            showRecordingsListDialog()
        end
    end
    
    btnCancel.onClick = function()
        vibrate()
        dialog.dismiss()
        showRecordingOptionsDialog(recording)
    end
end

function showRecordingOptions(recording)
    local layout = {
        LinearLayout,
        orientation = "vertical",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        padding = "20dp",
        backgroundColor = "#1E1E1E",
        {
            TextView,
            text = recording.name,
            textSize = "16sp",
            textColor = "#FFFFFF",
            gravity = "center",
            paddingBottom = "10dp"
        },
        {
            TextView,
            text = "Tamaño: " .. formatFileSize(recording.size),
            textSize = "14sp",
            textColor = "#888888",
            gravity = "center",
            paddingBottom = "20dp"
        },
        {
            Button,
            id = "btnPlay",
            text = "Reproducir",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginBottom = "10dp",
            backgroundColor = "#4CAF50",
            textColor = "#FFFFFF"
        },
        {
            Button,
            id = "btnShare",
            text = "Compartir",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginBottom = "10dp",
            backgroundColor = "#2196F3",
            textColor = "#FFFFFF"
        },
        {
            Button,
            id = "btnDelete",
            text = "Eliminar",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            layout_marginBottom = "10dp",
            backgroundColor = "#F44336",
            textColor = "#FFFFFF"
        },
        {
            Button,
            id = "btnBack",
            text = "Cancelar",
            layout_width = "match_parent",
            layout_height = "wrap_content",
            backgroundColor = "#757575",
            textColor = "#FFFFFF"
        }
    }
    
    local dialog = LuaDialog(context)
    dialog.setTitle("Opciones de grabación")
    local dialogView = loadlayout(layout)
    dialog.setView(dialogView)
    dialog.show()
    
    btnPlay.onClick = function()
        vibrate()
        dialog.dismiss()
        playRecording(recording.path)
    end
    
    btnShare.onClick = function()
        vibrate()
        dialog.dismiss()
        shareRecording(recording.path)
    end
    
    btnDelete.onClick = function()
        vibrate()
        dialog.dismiss()
        showDeleteRecordingDialog(recording)
    end
    
    btnBack.onClick = function()
        vibrate()
        dialog.dismiss()
    end
end

function playRecording(path)
    local success, error = pcall(function()
        local mediaPlayer = MediaPlayer()
        mediaPlayer.setDataSource(path)
        mediaPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC)
        mediaPlayer.prepare()
        mediaPlayer.start()
        
        showToast("Reproduciendo grabación")
        
        -- Detener después de 10 segundos o cuando termine
        local handler = Handler()
        handler.postDelayed(function()
            if mediaPlayer.isPlaying() then
                mediaPlayer.stop()
            end
            mediaPlayer.release()
        end, 10000)
    end)
    
    if not success then
        showToast("Error al reproducir: " .. tostring(error))
    end
end

function shareRecording(path)
    local file = File(path)
    if file.exists() then
        local uri = Uri.fromFile(file)
        local intent = Intent(Intent.ACTION_SEND)
        intent.setType("audio/*")
        intent.putExtra(Intent.EXTRA_STREAM, uri)
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        
        context.startActivity(Intent.createChooser(intent, "Compartir grabación"))
    else
        showToast("El archivo no existe")
    end
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

-- Vibrar al iniciar
local vibrator = context.getSystemService(Context.VIBRATOR_SERVICE)
vibrator.vibrate(100)

-- Crear carpetas necesarias
createFolders()

-- Cargar configuración
loadSettings()

-- Mostrar diálogo principal
showMainDialog()

return true