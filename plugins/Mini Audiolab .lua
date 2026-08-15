--[[
  ESTUDIO DE VOZ
  - ElevenLabs: voces en espa帽ol de alta calidad
  - Motores TTS nativos: todos los motores instalados en el sistema
  - Biblioteca: reproducir, eliminar, compartir, guardar, unir
  - Configuraci贸n avanzada de ElevenLabs
  Versi贸n: 2.0
  Autor: 脕ngel
--]]

require "import"
import "android.widget.*"
import "android.view.*"
import "android.os.*"
import "android.media.MediaPlayer"
import "android.media.MediaCodec"
import "android.media.MediaCodecInfo"
import "android.media.MediaFormat"
import "android.media.MediaMuxer"
import "android.graphics.Bitmap"
import "android.graphics.Canvas"
import "android.graphics.Color"
import "android.graphics.Paint"
import "android.speech.tts.TextToSpeech"
import "android.content.Intent"
import "android.net.Uri"
import "java.io.*"
import "cjson"
import "com.androlua.*"

local ctx = service

-- ============================================================================
-- API KEYS ELEVENLABS
-- ============================================================================

local EL_KEYS = {
    "sk_ac184c239322067c00ed2fee467607da5481f1da974c73d6",
    "sk_3cf4ed414a1f69230c058306ec351d43ac2f9692b123922f",
}
local EL_URL = "https://api.elevenlabs.io/v1/text-to-speech/"

-- ============================================================================
-- VOCES EN ESPA脩OL (ElevenLabs)
-- ============================================================================

local VOCES_EL = {
    -- 鈹€鈹€ VOCES FEMENINAS 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
    { nombre = "Jessica   鈾€ Joven 路 Expresiva 路 Conversacional",  id = "cgSgspJ2msm6clMCkdW9", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "Sarah     鈾€ Joven 路 Suave 路 Noticias",            id = "EXAVITQu4vr4xnSDxMaL", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "Aria      鈾€ Mediana 路 Expresiva 路 Redes sociales", id = "9BWtsMINqrJLrRacOk9x", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "Laura     鈾€ Joven 路 En茅rgica 路 Redes sociales",   id = "FGY2WhTYpPnrIDTdsKH5", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "Matilda   鈾€ Mediana 路 Amigable 路 Narraci贸n",      id = "XrExE9yKIg1WjnnlVkGX", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "Alice     鈾€ Mediana 路 Segura 路 Noticias",         id = "Xb7hH8MSUJpSbSDYk0k2", tag = "馃嚞馃嚙 Ingl茅s/Espa帽ol" },
    { nombre = "Lily      鈾€ Mediana 路 C谩lida 路 Narraci贸n",        id = "pFZP5JQG7iQjIQuC4Bku", tag = "馃嚞馃嚙 Ingl茅s/Espa帽ol" },
    { nombre = "Charlotte 鈾€ Joven 路 Seductora 路 Personajes",      id = "XB0fDUnXU5powFXDhCwa", tag = "馃嚫馃嚜 Ingl茅s/Espa帽ol" },
    { nombre = "Rachel    鈾€ Joven 路 Calmada 路 Narraci贸n",         id = "21m00Tcm4TlvDq8ikWAM", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "Domi      鈾€ Joven 路 Fuerte 路 Narraci贸n",          id = "AZnzlk1XvdvUeBnXmlld", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "Elli      鈾€ Joven 路 Emocional 路 Narraci贸n",       id = "MF3mGyEYCl7XYWbV9V6O", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "Serena    鈾€ Mediana 路 Agradable 路 Narraci贸n",     id = "pMsXgVXv3BLzUgSXRplE", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "Nicole    鈾€ Joven 路 Suave 路 Audiolibros",         id = "piTKgcLEGmPE4e6mEKli", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "River     鈿� Mediana 路 Segura 路 Redes sociales",   id = "SAz9YHcvj6GT2YYXdXww", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    -- 鈹€鈹€ VOCES MASCULINAS 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
    { nombre = "Eric      鈾� Mediano 路 Amigable 路 Conversacional", id = "cjVigY5qzO86Huf0OWal", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "Chris     鈾� Mediano 路 Casual 路 Conversacional",   id = "iP95p4xoKVk53GoZ742B", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "Brian     鈾� Mediano 路 Profundo 路 Narraci贸n",      id = "nPczCjzI2devNBz1zQrb", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "Liam      鈾� Joven 路 Articulado 路 Narraci贸n",      id = "TX3LPaxmHKxFdv7VOQHJ", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "Will      鈾� Joven 路 Amigable 路 Redes sociales",   id = "bIHbv24MWmeRgasZH58o", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "Roger     鈾� Mediano 路 Seguro 路 Redes sociales",   id = "CwhRBWXzGAHq8TQ4Fs17", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "Bill      鈾� Mayor 路 Confiable 路 Narraci贸n",       id = "pqHfZKP75CvOlQylNhV4", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "George    鈾� Mediano 路 C谩lido 路 Narraci贸n",        id = "JBFqnCBsd6RMkjVDRZzb", tag = "馃嚞馃嚙 Ingl茅s/Espa帽ol" },
    { nombre = "Daniel    鈾� Mediano 路 Autoritario 路 Noticias",    id = "onwK4e9ZLuTAKqWW03F9", tag = "馃嚞馃嚙 Ingl茅s/Espa帽ol" },
    { nombre = "Callum    鈾� Mediano 路 Intenso 路 Personajes",      id = "N2lVS1w4EtoT3dr4eOWO", tag = "馃寪 Ingl茅s/Espa帽ol" },
    { nombre = "Charlie   鈾� Mediano 路 Natural 路 Conversacional",  id = "IKne3meq5aSn9XLyUdCD", tag = "馃嚘馃嚭 Ingl茅s/Espa帽ol" },
    { nombre = "Josh      鈾� Joven 路 Profundo 路 Narraci贸n",        id = "TxGEqnHWrfWFTfGW9XjX", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "Antoni    鈾� Joven 路 Vers谩til 路 Narraci贸n",        id = "ErXwobaYiN019PkySvjV", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "Adam      鈾� Mediano 路 Profundo 路 Narraci贸n",      id = "pNInz6obpgDQGcFmaJgB", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "Arnold    鈾� Mediano 路 N铆tido 路 Narraci贸n",        id = "VR6AewLTigWG4xSOukaG", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
    { nombre = "Sam       鈾� Joven 路 Ronco 路 Redes sociales",      id = "yoZ06aMxZJJ28mfd3POQ", tag = "馃嚭馃嚫 Ingl茅s/Espa帽ol" },
}

-- ============================================================================
-- DIRECTORIOS
-- ============================================================================

local storage    = Environment.getExternalStorageDirectory().getPath()
local plugin_dir = storage .. "/Jieshuo/Plugins/estudio-voz"
local audio_dir  = storage .. "/Audios del Mini Audiolab"
local cfg_file   = plugin_dir .. "/config.json"

if not File(plugin_dir).exists() then File(plugin_dir).mkdirs() end
if not File(audio_dir).exists()  then File(audio_dir).mkdirs()  end

-- ============================================================================
-- CONFIGURACI脫N
-- ============================================================================

local cfg = {
    voz_el    = 1,
    stability = 0.5,
    similarity= 0.75,
    style     = 0.0,
    boost     = true,
    modelo    = "eleven_multilingual_v2",
    modo      = 1,  -- 1=ElevenLabs, 2=Motor nativo
}

local function cargarCfg()
    local f = io.open(cfg_file, "r")
    if f then
        local c = f:read("*a"); f:close()
        local ok, d = pcall(cjson.decode, c)
        if ok and type(d) == "table" then
            for k, v in pairs(d) do cfg[k] = v end
        end
    end
end

local function guardarCfg()
    local f = io.open(cfg_file, "w")
    if f then f:write(cjson.encode(cfg)); f:close() end
end

cargarCfg()

-- ============================================================================
-- ESTADO
-- ============================================================================

local voz_el_idx   = cfg.voz_el or 1
local generando    = false
local audio_actual = nil
local mediaPlayer  = nil
local seleccionados= {}
local tts_obj      = nil
local tts_motores  = {}     -- lista de {nombre, paquete}
local tts_motor_idx= 1
local tts_listo    = false

-- ============================================================================
-- MEDIAPLAYER
-- ============================================================================

local function liberarPlayer()
    if mediaPlayer then
        pcall(function() mediaPlayer.stop() end)
        pcall(function() mediaPlayer.release() end)
        mediaPlayer = nil
    end
end

local function reproducirAudio(path, onFin)
    liberarPlayer()
    local ok = pcall(function()
        mediaPlayer = MediaPlayer()
        mediaPlayer.setDataSource(path)
        mediaPlayer.prepare()
        mediaPlayer.start()
    end)
    if ok then
        ctx.asyncSpeak("Reproduciendo")
        if onFin then
            mediaPlayer.setOnCompletionListener(function() onFin() end)
        end
    else
        ctx.asyncSpeak("Error al reproducir")
    end
end

-- ============================================================================
-- UTILIDADES DE ARCHIVOS
-- ============================================================================

local function listarAudios()
    local result = {}
    local carpeta = File(audio_dir)
    if not carpeta.exists() then return result end
    local files = carpeta.listFiles()
    if files == nil then return result end
    local i = 0
    while true do
        local ok, f = pcall(function() return files[i] end)
        if not ok or f == nil then break end
        local nombre = tostring(f.getName())
        if nombre:lower():match("%.mp3$") or nombre:lower():match("%.wav$") then
            table.insert(result, {
                nombre = nombre,
                path   = tostring(f.getAbsolutePath()),
                size   = tonumber(tostring(f.length())) or 0,
                fecha  = tonumber(tostring(f.lastModified())) or 0
            })
        end
        i = i + 1
    end
    table.sort(result, function(a, b) return a.fecha > b.fecha end)
    return result
end

local function formatSize(b)
    if b >= 1048576 then return string.format("%.1f MB", b/1048576)
    elseif b >= 1024 then return string.format("%.1f KB", b/1024)
    end
    return tostring(b) .. " B"
end

local function copiarArchivo(src, dst)
    local f = io.open(src, "rb"); if not f then return false end
    local data = f:read("*a"); f:close()
    local g = io.open(dst, "wb"); if not g then return false end
    g:write(data); g:close(); return true
end

-- Empaquetado de enteros little-endian (sin operadores bit de Lua 5.3)
local function u32le(n)
    n = math.floor(n)
    local b1 = n % 256; n = math.floor(n / 256)
    local b2 = n % 256; n = math.floor(n / 256)
    local b3 = n % 256; n = math.floor(n / 256)
    local b4 = n % 256
    return string.char(b1, b2, b3, b4)
end

local function u16le(n)
    n = math.floor(n)
    local b1 = n % 256; n = math.floor(n / 256)
    local b2 = n % 256
    return string.char(b1, b2)
end

local function leerU16(s, pos)
    local b1, b2 = string.byte(s, pos, pos + 1)
    return (b1 or 0) + (b2 or 0) * 256
end

local function leerU32(s, pos)
    local b1, b2, b3, b4 = string.byte(s, pos, pos + 3)
    return (b1 or 0) + (b2 or 0) * 256 + (b3 or 0) * 65536 + (b4 or 0) * 16777216
end

-- Lee un archivo WAV y devuelve {sampleRate, numChannels, bitsPerSample, data}
-- o nil si no es un WAV PCM v谩lido de cabecera est谩ndar de 44 bytes
local function leerWAV(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local header = f:read(44)
    if not header or #header < 44 then f:close(); return nil end
    if header:sub(1, 4) ~= "RIFF" or header:sub(9, 12) ~= "WAVE" then
        f:close(); return nil
    end
    local info = {
        numChannels   = leerU16(header, 23),
        sampleRate    = leerU32(header, 25),
        bitsPerSample = leerU16(header, 35),
        data          = f:read("*a") or ""
    }
    f:close()
    return info
end

-- ============================================================================
-- AUDIO A VIDEO MP4 (experimental) - para subir a redes sociales
-- ADVERTENCIA: usa MediaCodec/MediaMuxer a bajo nivel. Cada etapa est谩
-- envuelta en pcall con mensaje de error espec铆fico para poder depurar.
-- ============================================================================

local BufferInfoClass = luajava.bindClass("android.media.MediaCodec$BufferInfo")
local ByteClassJava    = luajava.bindClass("byte")

-- Convierte un string Lua (binario) a un byte[] real de Java.
-- luajava.bytearray NO es invocable en este entorno (es una tabla, no funci贸n),
-- as铆 que se usa el patr贸n newArray + asignaci贸n por 铆ndice ya probado.
local function stringABytesJava(s)
    local n = #s
    local arr = luajava.newArray(ByteClassJava, n)
    for i = 1, n do
        local v = string.byte(s, i)
        if v > 127 then v = v - 256 end  -- unsigned (0-255) -> signed byte de Java (-128..127)
        arr[i - 1] = v
    end
    return arr
end

local function crearFondoYUV(ancho, alto, colorHex, etiqueta)
    local ok, resultado = pcall(function()
        local bmp = Bitmap.createBitmap(ancho, alto, Bitmap.Config.ARGB_8888)
        local canvas = Canvas(bmp)
        canvas.drawColor(colorHex)
        if etiqueta and etiqueta ~= "" then
            local paint = Paint()
            paint.setColor(0xFFFFFFFF)
            paint.setTextSize(alto * 0.07)
            paint.setAntiAlias(true)
            paint.setTextAlign(Paint.Align.CENTER)
            canvas.drawText(etiqueta, ancho / 2, alto / 2, paint)
        end
        local total = ancho * alto
        local IntClass = luajava.bindClass("int")
        local pixeles = luajava.newArray(IntClass, total)
        bmp.getPixels(pixeles, 0, ancho, 0, 0, ancho, alto)
        local ySize, uvSize = ancho * alto, math.floor(ancho * alto / 4)
        local yBuf, uBuf, vBuf = {}, {}, {}
        for j = 0, alto - 1 do
            for i = 0, ancho - 1 do
                local idx = j * ancho + i
                local pixel = pixeles[idx]
                if pixel < 0 then pixel = pixel + 4294967296 end
                local r = math.floor(pixel / 65536) % 256
                local g = math.floor(pixel / 256) % 256
                local b = pixel % 256
                local y = math.max(0, math.min(255, math.floor(0.299*r + 0.587*g + 0.114*b)))
                yBuf[idx + 1] = y
                if i % 2 == 0 and j % 2 == 0 then
                    local u = math.max(0, math.min(255, math.floor(-0.169*r - 0.331*g + 0.5*b + 128)))
                    local v = math.max(0, math.min(255, math.floor(0.5*r - 0.419*g - 0.081*b + 128)))
                    local uvIdx = math.floor(j/2) * math.floor(ancho/2) + math.floor(i/2)
                    uBuf[uvIdx + 1] = u
                    vBuf[uvIdx + 1] = v
                end
            end
        end
        local function tablaAString(t, n)
            local partes = {}
            for k = 1, n do partes[k] = string.char(t[k] or 0) end
            return table.concat(partes)
        end
        return tablaAString(yBuf, ySize) .. tablaAString(uBuf, uvSize) .. tablaAString(vBuf, uvSize)
    end)
    if not ok then return nil, "Error generando el fondo de video: " .. tostring(resultado) end
    return resultado
end

local function convertirWAVaMP4(wavPath, mp4Path, tvLogRef)
    local function log(msg) if tvLogRef then tvLogRef.setText(msg) end end

    log("Leyendo WAV...")
    local wav = leerWAV(wavPath)
    if not wav then return false, "El archivo no es un WAV v谩lido" end

    local bytesPorMuestra = wav.bitsPerSample / 8
    local duracionSeg = #wav.data / (wav.sampleRate * wav.numChannels * bytesPorMuestra)
    if duracionSeg < 1 then duracionSeg = 1 end
    local totalFramesVideo = math.ceil(duracionSeg)

    log("Generando fondo de video...")
    local ANCHO, ALTO = 720, 720
    local yuvFrame, errYuv = crearFondoYUV(ANCHO, ALTO, 0xFF7C3AED, "馃帣锔� Mini Audiolab")
    if not yuvFrame then return false, errYuv end

    log("Configurando encoder de video...")
    local okV, videoEncoder = pcall(function()
        local fmt = MediaFormat.createVideoFormat("video/avc", ANCHO, ALTO)
        fmt.setInteger(MediaFormat.KEY_COLOR_FORMAT, 19) -- 19 = COLOR_FormatYUV420Planar (constante estable del SDK de Android)
        fmt.setInteger(MediaFormat.KEY_BIT_RATE, 1000000)
        fmt.setInteger(MediaFormat.KEY_FRAME_RATE, 1)
        fmt.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
        local enc = MediaCodec.createEncoderByType("video/avc")
        enc.configure(fmt, nil, nil, MediaCodec.CONFIGURE_FLAG_ENCODE)
        enc.start()
        return enc
    end)
    if not okV then return false, "El dispositivo no admite este encoder de video: " .. tostring(videoEncoder) end

    log("Configurando encoder de audio...")
    local okA, audioEncoder = pcall(function()
        local fmt = MediaFormat.createAudioFormat("audio/mp4a-latm", wav.sampleRate, wav.numChannels)
        fmt.setInteger(MediaFormat.KEY_BIT_RATE, 128000)
        fmt.setInteger(MediaFormat.KEY_AAC_PROFILE, 2) -- 2 = AACObjectLC (constante estable del SDK de Android)
        local enc = MediaCodec.createEncoderByType("audio/mp4a-latm")
        enc.configure(fmt, nil, nil, MediaCodec.CONFIGURE_FLAG_ENCODE)
        enc.start()
        return enc
    end)
    if not okA then
        pcall(function() videoEncoder.stop(); videoEncoder.release() end)
        return false, "El dispositivo no admite este encoder de audio: " .. tostring(audioEncoder)
    end

    log("Preparando archivo MP4...")
    local okM, muxer = pcall(function()
        return MediaMuxer(mp4Path, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
    end)
    if not okM then
        pcall(function() videoEncoder.stop(); videoEncoder.release() end)
        pcall(function() audioEncoder.stop(); audioEncoder.release() end)
        return false, "No se pudo crear el archivo MP4 de salida: " .. tostring(muxer)
    end

    local bufferInfo = BufferInfoClass()
    local videoTrack, audioTrack = -1, -1
    local muxerIniciado = false

    local function drenar(encoder, esVideo, timeoutUs)
        local salida = encoder.dequeueOutputBuffer(bufferInfo, timeoutUs)
        if salida == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED then
            local formato = encoder.getOutputFormat()
            if esVideo then videoTrack = muxer.addTrack(formato)
            else audioTrack = muxer.addTrack(formato) end
            if videoTrack >= 0 and audioTrack >= 0 and not muxerIniciado then
                muxer.start(); muxerIniciado = true
            end
            return true, "formato_cambiado"
        elseif salida >= 0 then
            local buf = encoder.getOutputBuffer(salida)
            local track = esVideo and videoTrack or audioTrack
            if muxerIniciado and track >= 0 and bufferInfo.size > 0 then
                buf.position(bufferInfo.offset)
                buf.limit(bufferInfo.offset + bufferInfo.size)
                muxer.writeSampleData(track, buf, bufferInfo)
            end
            encoder.releaseOutputBuffer(salida, false)
            local esFin = (bufferInfo.flags == MediaCodec.BUFFER_FLAG_END_OF_STREAM)
            return true, esFin and "fin" or "dato"
        end
        return false, "esperar"
    end

    log("Preparando datos de video...")
    local okVid, errVid = pcall(function()
        -- Se convierte UNA sola vez y se reutiliza en cada fotograma (mismo contenido siempre)
        local yuvFrameJava = stringABytesJava(yuvFrame)

        log("Codificando video (" .. totalFramesVideo .. " fotogramas)...")
        local frameIdx = 0
        while frameIdx < totalFramesVideo do
            local entrada = videoEncoder.dequeueInputBuffer(10000)
            if entrada >= 0 then
                local buf = videoEncoder.getInputBuffer(entrada)
                buf.clear()
                buf.put(yuvFrameJava)
                local ptsUs = frameIdx * 1000000
                local flag = (frameIdx == totalFramesVideo - 1) and MediaCodec.BUFFER_FLAG_END_OF_STREAM or 0
                videoEncoder.queueInputBuffer(entrada, 0, #yuvFrame, ptsUs, flag)
                frameIdx = frameIdx + 1
            end
            local continuar = true
            while continuar do continuar = drenar(videoEncoder, true, 5000) end
        end
        local fin, intentos = false, 0
        while not fin and intentos < 200 do
            local ok2, tipo = drenar(videoEncoder, true, 10000)
            if tipo == "fin" then fin = true end
            intentos = intentos + 1
        end
    end)
    if not okVid then
        pcall(function() videoEncoder.stop(); videoEncoder.release(); audioEncoder.stop(); audioEncoder.release(); muxer.release() end)
        return false, "Fallo codificando video: " .. tostring(errVid)
    end

    log("Codificando audio...")
    local okAud, errAud = pcall(function()
        local CHUNK = 4096
        local pos, total, ptsUs = 1, #wav.data, 0
        local bytesPorSeg = wav.sampleRate * wav.numChannels * bytesPorMuestra
        while pos <= total do
            local entrada = audioEncoder.dequeueInputBuffer(10000)
            if entrada >= 0 then
                local fin = math.min(pos + CHUNK - 1, total)
                local trozo = wav.data:sub(pos, fin)
                local buf = audioEncoder.getInputBuffer(entrada)
                buf.clear()
                buf.put(stringABytesJava(trozo))
                local esUltimo = (fin >= total)
                local flag = esUltimo and MediaCodec.BUFFER_FLAG_END_OF_STREAM or 0
                audioEncoder.queueInputBuffer(entrada, 0, #trozo, ptsUs, flag)
                ptsUs = ptsUs + math.floor((#trozo / bytesPorSeg) * 1000000)
                pos = fin + 1
            end
            local continuar = true
            while continuar do continuar = drenar(audioEncoder, false, 5000) end
        end
        local fin2, intentos = false, 0
        while not fin2 and intentos < 200 do
            local ok2, tipo = drenar(audioEncoder, false, 10000)
            if tipo == "fin" then fin2 = true end
            intentos = intentos + 1
        end
    end)
    if not okAud then
        pcall(function() videoEncoder.stop(); videoEncoder.release(); audioEncoder.stop(); audioEncoder.release(); muxer.release() end)
        return false, "Fallo codificando audio: " .. tostring(errAud)
    end

    log("Finalizando archivo...")
    local okFin, errFin = pcall(function()
        muxer.stop(); muxer.release()
        videoEncoder.stop(); videoEncoder.release()
        audioEncoder.stop(); audioEncoder.release()
    end)
    if not okFin then return false, "Fallo al finalizar el MP4: " .. tostring(errFin) end

    return true, "OK"
end

local function crearHeaderWAV(dataSize, sampleRate, numChannels, bitsPerSample)
    local byteRate   = sampleRate * numChannels * (bitsPerSample / 8)
    local blockAlign = numChannels * (bitsPerSample / 8)
    local chunkSize   = 36 + dataSize
    local h = "RIFF" .. u32le(chunkSize) .. "WAVE" .. "fmt " .. u32le(16)
    h = h .. u16le(1) .. u16le(numChannels) .. u32le(sampleRate)
    h = h .. u32le(byteRate) .. u16le(blockAlign) .. u16le(bitsPerSample)
    h = h .. "data" .. u32le(dataSize)
    return h
end

-- Une varios WAV en uno solo, validando que compartan formato.
-- Devuelve true / false, mensaje
local function unirAudios(paths, output)
    local infos = {}
    for _, p in ipairs(paths) do
        local info = leerWAV(p)
        if not info then return false, "archivo_invalido" end
        table.insert(infos, info)
    end

    local base = infos[1]
    for i = 2, #infos do
        if infos[i].sampleRate ~= base.sampleRate
        or infos[i].numChannels ~= base.numChannels
        or infos[i].bitsPerSample ~= base.bitsPerSample then
            return false, "formato_distinto"
        end
    end

    local partes = {}
    for _, info in ipairs(infos) do table.insert(partes, info.data) end
    local dataFinal = table.concat(partes)
    local header = crearHeaderWAV(#dataFinal, base.sampleRate, base.numChannels, base.bitsPerSample)

    local g = io.open(output, "wb")
    if not g then return false, "no_se_pudo_crear" end
    g:write(header); g:write(dataFinal); g:close()
    return true
end

local function compartirAudio(path)
    pcall(function()
        local intent = Intent(Intent.ACTION_SEND)
        intent.setType("audio/*")
        intent.putExtra(Intent.EXTRA_STREAM, Uri.fromFile(File(path)))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        ctx.startActivity(Intent.createChooser(intent, "Compartir audio"):addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    end)
end

local function sanitizar(s)
    return s:gsub('[/\\:*?"<>|]', "_")
end

-- ============================================================================
-- TTS NATIVO - inicializar y listar motores
-- ============================================================================

local function inicializarTTS(onListo)
    if tts_obj then tts_obj.shutdown() end
    tts_listo  = false
    tts_motores= {}

    tts_obj = TextToSpeech(ctx, TextToSpeech.OnInitListener{
        onInit = function(status)
            if status == TextToSpeech.SUCCESS then
                -- Listar motores instalados
                local engines = tts_obj.getEngines()
                if engines then
                    for i = 0, engines.size() - 1 do
                        local eng = engines.get(i)
                        local nombre  = tostring(eng.label  or eng.name)
                        local paquete = tostring(eng.name)
                        table.insert(tts_motores, { nombre = nombre, paquete = paquete })
                    end
                end
                tts_listo = true
                if onListo then onListo() end
            else
                ctx.asyncSpeak("Error al inicializar TTS")
            end
        end
    })
end

-- Clases Java que no vienen en los imports por wildcard
local HashMapClass = luajava.bindClass("java.util.HashMap")
local LocaleClass  = luajava.bindClass("java.util.Locale")

-- Genera un WAV con el motor nativo y llama onDone(path) al terminar
local function generarWAVNativo(texto, paquete, nombre_arch, onDone)
    local path = audio_dir .. "/" .. sanitizar(nombre_arch) .. ".wav"
    local outputFile = File(path)
    if outputFile.exists() then outputFile.delete() end

    local handler = Handler(ctx.getMainLooper())

    tts_obj.setOnUtteranceCompletedListener(
        luajava.createProxy("android.speech.tts.TextToSpeech$OnUtteranceCompletedListener", {
            onUtteranceCompleted = function(uid)
                if uid == "estudio_voz" then
                    handler.postDelayed(function()
                        if onDone then onDone(path) end
                    end, 200)
                end
            end
        })
    )

    if Build.VERSION.SDK_INT >= 21 then
        local bundle = Bundle()
        bundle.putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, "estudio_voz")
        tts_obj.synthesizeToFile(texto, bundle, outputFile, "estudio_voz")
    else
        local params = HashMapClass()
        params.put(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, "estudio_voz")
        tts_obj.synthesizeToFile(texto, params, path)
    end
end

local function usarMotorNativo(paquete, onListo)
    if tts_obj then tts_obj.shutdown() end
    tts_listo = false
    tts_obj = TextToSpeech(ctx, TextToSpeech.OnInitListener{
        onInit = function(status)
            if status == TextToSpeech.SUCCESS then
                tts_obj.setLanguage(LocaleClass("es"))
                tts_listo = true
                if onListo then onListo() end
            else
                ctx.asyncSpeak("Error con el motor " .. paquete)
            end
        end
    }, paquete)
end

-- ============================================================================
-- LAYOUT (3 pesta帽as)
-- ============================================================================

local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = "#0D0D0D",
    -- TABS
    {
        LinearLayout,
        orientation = "horizontal",
        layout_width = "fill",
        backgroundColor = "#111111",
        {
            Button, id = "tabCrear",
            text = "馃帣 Crear",
            layout_weight = 1,
            backgroundColor = "#7C3AED",
            textColor = "#FFFFFF", textSize = "12sp"
        },
        {
            Button, id = "tabBiblioteca",
            text = "馃搨 Audios",
            layout_weight = 1,
            backgroundColor = "#333333",
            textColor = "#FFFFFF", textSize = "12sp"
        },
        {
            Button, id = "tabAjustes",
            text = "鈿� Ajustes",
            layout_weight = 1,
            backgroundColor = "#333333",
            textColor = "#FFFFFF", textSize = "12sp"
        }
    },
    -- ===== PANEL CREAR =====
    {
        ScrollView,
        id = "panelCrear",
        layout_width = "fill",
        layout_height = "0dp",
        layout_weight = 1,
        {
            LinearLayout,
            orientation = "vertical",
            layout_width = "fill",
            padding = "10dp",
            -- Selector de modo
            {
                LinearLayout,
                orientation = "horizontal",
                layout_width = "fill",
                layout_marginBottom = "6dp",
                {
                    Button, id = "btnModoEL",
                    text = "鉁� ElevenLabs",
                    layout_weight = 1,
                    backgroundColor = "#4C1D95",
                    textColor = "#FFFFFF", textSize = "12sp"
                },
                {
                    Button, id = "btnModoNativo",
                    text = "Motor del sistema",
                    layout_weight = 1,
                    backgroundColor = "#333333",
                    textColor = "#FFFFFF", textSize = "12sp"
                }
            },
            -- Selector voz ElevenLabs
            {
                Button, id = "btnVozEL",
                text = "馃帳 " .. VOCES_EL[voz_el_idx].nombre,
                layout_width = "fill",
                id = "btnVozEL",
                backgroundColor = "#1E1B4B",
                textColor = "#C4B5FD",
                textSize = "12sp",
                layout_marginBottom = "4dp"
            },
            -- Selector motor nativo
            {
                Button, id = "btnMotorNativo",
                text = "馃攰 Motor: cargando...",
                layout_width = "fill",
                backgroundColor = "#1A2E1A",
                textColor = "#86EFAC",
                textSize = "12sp",
                layout_marginBottom = "4dp"
            },
            -- Texto
            {
                EditText, id = "editTexto",
                hint = "Escribe el texto a convertir...",
                layout_width = "fill",
                lines = 6,
                textColor = "#FFFFFF",
                hintTextColor = "#555555",
                backgroundColor = "#1E1E1E",
                padding = "8dp",
                layout_marginBottom = "4dp"
            },
            -- Nombre del archivo
            {
                EditText, id = "editNombre",
                hint = "Nombre del archivo (opcional)...",
                layout_width = "fill",
                textColor = "#FFFFFF",
                hintTextColor = "#555555",
                backgroundColor = "#1E1E1E",
                padding = "8dp",
                layout_marginBottom = "6dp"
            },
            -- Bot贸n generar
            {
                Button, id = "btnGenerar",
                text = "馃帣锔� Generar audio",
                layout_width = "fill",
                backgroundColor = "#7C3AED",
                textColor = "#FFFFFF",
                padding = "10dp"
            },
            -- Estado
            {
                TextView, id = "tvEstado",
                text = "Listo",
                textSize = "12sp",
                textColor = "#AAAAAA",
                gravity = "center",
                padding = "4dp"
            },
            -- Controles del 煤ltimo audio generado
            {
                LinearLayout, id = "panelPlayer",
                orientation = "horizontal",
                layout_width = "fill",
                layout_marginTop = "4dp",
                {
                    Button, id = "btnPlayPause",
                    text = "鈻� Reproducir",
                    layout_weight = 1,
                    backgroundColor = "#065F46",
                    textColor = "#FFFFFF", textSize = "11sp"
                },
                {
                    Button, id = "btnGuardarDesc",
                    text = "馃捑 Guardar",
                    layout_weight = 1,
                    backgroundColor = "#1E3A5F",
                    textColor = "#FFFFFF", textSize = "11sp"
                },
                {
                    Button, id = "btnCompartirUlt",
                    text = "馃摛 Compartir",
                    layout_weight = 1,
                    backgroundColor = "#4A1942",
                    textColor = "#FFFFFF", textSize = "11sp"
                },
                {
                    Button, id = "btnVideoUlt",
                    text = "馃幀 MP4",
                    layout_weight = 1,
                    backgroundColor = "#78350F",
                    textColor = "#FFFFFF", textSize = "11sp"
                }
            },
            {
                Button, id = "btnCerrar",
                text = "鉁� Cerrar",
                layout_width = "fill",
                backgroundColor = "#B71C1C",
                textColor = "#FFFFFF",
                layout_marginTop = "6dp"
            }
        }
    },
    -- ===== PANEL BIBLIOTECA =====
    {
        LinearLayout, id = "panelBiblioteca",
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "0dp",
        layout_weight = 1,
        {
            LinearLayout,
            orientation = "horizontal",
            layout_width = "fill",
            padding = "6dp",
            {
                Button, id = "btnRefrescar",
                text = "馃攧",
                layout_weight = 1,
                backgroundColor = "#333333",
                textColor = "#FFFFFF", textSize = "11sp"
            },
            {
                Button, id = "btnUnir",
                text = "馃敆 Unir seleccionados",
                layout_weight = 3,
                backgroundColor = "#78350F",
                textColor = "#FFFFFF", textSize = "11sp"
            }
        },
        {
            TextView, id = "tvInfoBib",
            text = "Toca un audio para ver sus opciones",
            textColor = "#888888",
            textSize = "11sp",
            gravity = "center",
            padding = "4dp"
        },
        {
            ScrollView,
            layout_width = "fill",
            layout_height = "0dp",
            layout_weight = 1,
            {
                LinearLayout, id = "contenedorAudios",
                orientation = "vertical",
                layout_width = "fill",
                padding = "6dp"
            }
        }
    },
    -- ===== PANEL AJUSTES =====
    {
        ScrollView, id = "panelAjustes",
        layout_width = "fill",
        layout_height = "0dp",
        layout_weight = 1,
        {
            LinearLayout,
            orientation = "vertical",
            layout_width = "fill",
            padding = "12dp",
            {
                TextView,
                text = "鈿欙笍 Configuraci贸n ElevenLabs",
                textColor = "#A78BFA", textSize = "16sp",
                gravity = "center", padding = "8dp"
            },
            -- Estabilidad
            {
                TextView, text = "Estabilidad",
                textColor = "#AAAAAA", textSize = "11sp",
                layout_marginTop = "6dp"
            },
            {
                LinearLayout, orientation = "horizontal",
                layout_width = "fill", layout_marginBottom = "10dp",
                {
                    Button, id = "btnEstMenos", text = " 鈭� ",
                    layout_weight = 1,
                    backgroundColor = "#333333", textColor = "#FFFFFF"
                },
                {
                    TextView, id = "tvEstVal",
                    text = string.format("%.2f", cfg.stability),
                    layout_weight = 2, gravity = "center",
                    textColor = "#FFFFFF", textSize = "18sp"
                },
                {
                    Button, id = "btnEstMas", text = " + ",
                    layout_weight = 1,
                    backgroundColor = "#333333", textColor = "#FFFFFF"
                }
            },
            -- Similitud
            {
                TextView, text = "Similitud",
                textColor = "#AAAAAA", textSize = "11sp"
            },
            {
                LinearLayout, orientation = "horizontal",
                layout_width = "fill", layout_marginBottom = "10dp",
                {
                    Button, id = "btnSimMenos", text = " 鈭� ",
                    layout_weight = 1,
                    backgroundColor = "#333333", textColor = "#FFFFFF"
                },
                {
                    TextView, id = "tvSimVal",
                    text = string.format("%.2f", cfg.similarity),
                    layout_weight = 2, gravity = "center",
                    textColor = "#FFFFFF", textSize = "18sp"
                },
                {
                    Button, id = "btnSimMas", text = " + ",
                    layout_weight = 1,
                    backgroundColor = "#333333", textColor = "#FFFFFF"
                }
            },
            -- Estilo
            {
                TextView, text = "Estilo",
                textColor = "#AAAAAA", textSize = "11sp"
            },
            {
                LinearLayout, orientation = "horizontal",
                layout_width = "fill", layout_marginBottom = "10dp",
                {
                    Button, id = "btnStyMenos", text = " 鈭� ",
                    layout_weight = 1,
                    backgroundColor = "#333333", textColor = "#FFFFFF"
                },
                {
                    TextView, id = "tvStyVal",
                    text = string.format("%.2f", cfg.style),
                    layout_weight = 2, gravity = "center",
                    textColor = "#FFFFFF", textSize = "18sp"
                },
                {
                    Button, id = "btnStyMas", text = " + ",
                    layout_weight = 1,
                    backgroundColor = "#333333", textColor = "#FFFFFF"
                }
            },
            -- Boost
            {
                Button, id = "btnBoost",
                text = cfg.boost and "鉁� Speaker boost: ON" or "鉂� Speaker boost: OFF",
                layout_width = "fill",
                backgroundColor = cfg.boost and 0xFF065F46 or 0xFF333333,
                textColor = "#FFFFFF",
                layout_marginBottom = "10dp"
            },
            -- Modelo
            {
                Button, id = "btnModelo",
                text = "馃 " .. (cfg.modelo == "eleven_turbo_v2_5" and "Turbo v2.5" or "Multiling眉e v2"),
                layout_width = "fill",
                backgroundColor = "#1E1B4B",
                textColor = "#C4B5FD",
                layout_marginBottom = "10dp"
            },
            {
                Button, id = "btnGuardarCfg",
                text = "馃捑 Guardar configuraci贸n",
                layout_width = "fill",
                backgroundColor = "#7C3AED",
                textColor = "#FFFFFF",
                padding = "10dp"
            }
        }
    }
}

local view = loadlayout(layout)

-- Ocultar paneles al inicio
panelBiblioteca.setVisibility(View.GONE)
panelAjustes.setVisibility(View.GONE)
panelPlayer.setVisibility(View.GONE)
btnUnir.setVisibility(View.GONE)
btnMotorNativo.setVisibility(View.GONE)

-- ============================================================================
-- NAVEGACI脫N POR PESTA脩AS
-- ============================================================================

local renderizarBiblioteca  -- declaraci贸n anticipada

local function mostrarTab(n)
    panelCrear.setVisibility(n == 1 and View.VISIBLE or View.GONE)
    panelBiblioteca.setVisibility(n == 2 and View.VISIBLE or View.GONE)
    panelAjustes.setVisibility(n == 3 and View.VISIBLE or View.GONE)
    tabCrear.setBackgroundColor(n == 1 and 0xFF7C3AED or 0xFF333333)
    tabBiblioteca.setBackgroundColor(n == 2 and 0xFF7C3AED or 0xFF333333)
    tabAjustes.setBackgroundColor(n == 3 and 0xFF7C3AED or 0xFF333333)
    if n == 2 then renderizarBiblioteca() end
end

tabCrear.onClick      = function() mostrarTab(1) end
tabBiblioteca.onClick = function() mostrarTab(2) end
tabAjustes.onClick    = function() mostrarTab(3) end

-- ============================================================================
-- MODO
-- ============================================================================

local function actualizarModo()
    if cfg.modo == 1 then
        btnModoEL.setBackgroundColor(0xFF4C1D95)
        btnModoEL.setText("鉁� ElevenLabs")
        btnModoNativo.setBackgroundColor(0xFF333333)
        btnModoNativo.setText("Motor del sistema")
        btnVozEL.setVisibility(View.VISIBLE)
        btnMotorNativo.setVisibility(View.GONE)
    else
        btnModoNativo.setBackgroundColor(0xFF1A3A1A)
        btnModoNativo.setText("鉁� Motor del sistema")
        btnModoEL.setBackgroundColor(0xFF333333)
        btnModoEL.setText("ElevenLabs")
        btnVozEL.setVisibility(View.GONE)
        btnMotorNativo.setVisibility(View.VISIBLE)
    end
end

btnModoEL.onClick = function()
    cfg.modo = 1
    actualizarModo()
    ctx.asyncSpeak("ElevenLabs")
end

btnModoNativo.onClick = function()
    cfg.modo = 2
    actualizarModo()
    ctx.asyncSpeak("Motor del sistema")
    if not tts_listo then
        tvEstado.setText("鈴� Cargando motores del sistema...")
        inicializarTTS(function()
            if #tts_motores > 0 then
                btnMotorNativo.setText("馃攰 " .. tts_motores[tts_motor_idx].nombre)
                tvEstado.setText("鉁� " .. #tts_motores .. " motores disponibles")
                ctx.asyncSpeak(#tts_motores .. " motores disponibles")
            else
                tvEstado.setText("No se encontraron motores TTS")
                ctx.asyncSpeak("No se encontraron motores TTS instalados")
            end
        end)
    end
end

actualizarModo()

-- ============================================================================
-- SELECTOR VOZ ELEVENLABS (con LuaDialog)
-- ============================================================================

btnVozEL.onClick = function()
    local svLayout = {
        ScrollView,
        layout_width = "fill",
        layout_height = "300dp",
        {
            LinearLayout, id = "listaVocesEL",
            orientation = "vertical",
            layout_width = "fill",
            padding = "4dp"
        }
    }
    local svView = loadlayout(svLayout)
    for i, v in ipairs(VOCES_EL) do
        local btn = Button(ctx)
        btn.setText((i == voz_el_idx and "鉁� " or "   ") .. v.nombre)
        btn.setTextColor(0xFFFFFFFF)
        btn.setBackgroundColor(i == voz_el_idx and 0xFF4C1D95 or 0xFF1E1E1E)
        btn.setTextSize(13)
        local p = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT)
        p.setMargins(0, 2, 0, 2)
        local idx = i
        btn.onClick = function()
            voz_el_idx = idx
            cfg.voz_el = idx
            btnVozEL.setText("馃帳 " .. VOCES_EL[idx].nombre)
            ctx.asyncSpeak("Voz: " .. VOCES_EL[idx].nombre)
            dlgVoz.dismiss()
        end
        listaVocesEL.addView(btn, p)
    end
    dlgVoz = LuaDialog(ctx)
    dlgVoz.setTitle("Voces en espa帽ol")
    dlgVoz.setView(svView)
    dlgVoz.setNegativeButton("Cancelar", nil)
    dlgVoz.show()
end

-- ============================================================================
-- SELECTOR MOTOR NATIVO (con LuaDialog)
-- ============================================================================

btnMotorNativo.onClick = function()
    if not tts_listo or #tts_motores == 0 then
        ctx.asyncSpeak("Espera, cargando motores")
        return
    end

    local svLayout2 = {
        ScrollView,
        layout_width = "fill",
        layout_height = "300dp",
        {
            LinearLayout, id = "listaMotores",
            orientation = "vertical",
            layout_width = "fill",
            padding = "4dp"
        }
    }
    local svView2 = loadlayout(svLayout2)
    for i, m in ipairs(tts_motores) do
        local btn = Button(ctx)
        btn.setText((i == tts_motor_idx and "鉁� " or "   ") .. m.nombre)
        btn.setTextColor(0xFFFFFFFF)
        btn.setBackgroundColor(i == tts_motor_idx and 0xFF1A3A1A or 0xFF1E1E1E)
        btn.setTextSize(13)
        local p = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT)
        p.setMargins(0, 2, 0, 2)
        local idx = i
        btn.onClick = function()
            tts_motor_idx = idx
            btnMotorNativo.setText("馃攰 " .. tts_motores[idx].nombre)
            ctx.asyncSpeak("Motor: " .. tts_motores[idx].nombre)
            dlgMotor.dismiss()
        end
        listaMotores.addView(btn, p)
    end
    dlgMotor = LuaDialog(ctx)
    dlgMotor.setTitle("Seleccionar motor TTS")
    dlgMotor.setView(svView2)
    dlgMotor.setNegativeButton("Cancelar", nil)
    dlgMotor.show()
end

-- ============================================================================
-- GENERACI脫N CON ELEVENLABS (rotaci贸n autom谩tica)
-- ============================================================================

local function generarEL(texto, nombre_arch, intento)
    intento = intento or 1
    if intento > #EL_KEYS then
        tvEstado.setText("鉂� Todas las API keys fallaron.")
        ctx.asyncSpeak("Todas las keys agotadas")
        generando = false; return
    end

    tvEstado.setText("鈴� Generando con ElevenLabs (key " .. intento .. ")...")

    -- output_format=wav_24000: WAV nativo real (sin conversion), disponible en plan gratuito.
    -- (wav_44100 requiere plan Pro; 24000 Hz es m谩s que suficiente para voz)
    local url  = EL_URL .. VOCES_EL[voz_el_idx].id .. "?output_format=wav_24000"
    local body = cjson.encode({
        text     = texto,
        model_id = cfg.modelo,
        voice_settings = {
            stability         = cfg.stability,
            similarity_boost  = cfg.similarity,
            style             = cfg.style,
            use_speaker_boost = cfg.boost
        }
    })
    local headers = {
        ["xi-api-key"]   = EL_KEYS[intento],
        ["Content-Type"] = "application/json",
        ["Accept"]       = "audio/wav"
    }

    Http.post(url, body, headers, function(code, respuesta)
        if code == 401 or code == 403 or code == 429 then
            tvEstado.setText("Key " .. intento .. " fall贸 (" .. code .. "). Siguiente...")
            generarEL(texto, nombre_arch, intento + 1)
            return
        end
        if code ~= 200 then
            tvEstado.setText("Error " .. tostring(code) .. ". Siguiente key...")
            generarEL(texto, nombre_arch, intento + 1)
            return
        end
        if not respuesta or #respuesta < 100 then
            tvEstado.setText("Respuesta vac铆a. Siguiente key...")
            generarEL(texto, nombre_arch, intento + 1)
            return
        end

        local nombre = nombre_arch ~= "" and sanitizar(nombre_arch) or ("audio_" .. os.time())
        local path   = audio_dir .. "/" .. nombre .. ".wav"
        local f      = io.open(path, "wb")
        if f then
            f:write(respuesta); f:close()
            audio_actual = path
            tvEstado.setText("鉁� " .. nombre .. ".wav")
            ctx.asyncSpeak("Audio generado")
            panelPlayer.setVisibility(View.VISIBLE)
            btnPlayPause.setText("鈴� Pausar")
            reproducirAudio(path, function()
                btnPlayPause.setText("鈻� Reproducir")
            end)
        else
            tvEstado.setText("鉂� Error al guardar.")
        end
        generando = false
    end)
end

-- ============================================================================
-- GENERACI脫N CON MOTOR NATIVO
-- ============================================================================

local function generarNativo(texto, nombre_arch)
    if not tts_listo or #tts_motores == 0 then
        ctx.asyncSpeak("Motores no disponibles"); generando = false; return
    end

    local motor = tts_motores[tts_motor_idx]
    local nombre = nombre_arch ~= "" and sanitizar(nombre_arch) or ("nativo_" .. os.time())
    tvEstado.setText("鈴� Generando con " .. motor.nombre .. "...")

    usarMotorNativo(motor.paquete, function()
        generarWAVNativo(texto, motor.paquete, nombre, function(path)
            if File(path).exists() and File(path).length() > 0 then
                audio_actual = path
                tvEstado.setText("鉁� " .. nombre .. ".wav")
                ctx.asyncSpeak("Audio generado con " .. motor.nombre)
                panelPlayer.setVisibility(View.VISIBLE)
                btnPlayPause.setText("鈴� Pausar")
                reproducirAudio(path, function()
                    btnPlayPause.setText("鈻� Reproducir")
                end)
            else
                tvEstado.setText("鉂� El motor no gener贸 audio.")
                ctx.asyncSpeak("El motor no gener贸 audio")
            end
            generando = false
        end)
    end)
end

-- ============================================================================
-- BOT脫N GENERAR
-- ============================================================================

btnGenerar.onClick = function()
    local texto  = editTexto.getText().toString():gsub("^%s+",""):gsub("%s+$","")
    local nombre = editNombre.getText().toString():gsub("^%s+",""):gsub("%s+$","")
    if texto == "" then ctx.asyncSpeak("Escribe algo primero"); return end
    if generando then ctx.asyncSpeak("Espera, hay una generaci贸n en proceso"); return end
    generando = true

    if cfg.modo == 1 then
        generarEL(texto, nombre, 1)
    else
        generarNativo(texto, nombre)
    end
end

-- ============================================================================
-- CONTROLES DEL 脷LTIMO AUDIO
-- ============================================================================

btnPlayPause.onClick = function()
    if not audio_actual then ctx.asyncSpeak("No hay audio generado"); return end
    if mediaPlayer == nil then
        btnPlayPause.setText("鈴� Pausar")
        reproducirAudio(audio_actual, function() btnPlayPause.setText("鈻� Reproducir") end)
    elseif mediaPlayer.isPlaying() then
        mediaPlayer.pause()
        btnPlayPause.setText("鈻� Reproducir")
        ctx.asyncSpeak("Pausado")
    else
        mediaPlayer.start()
        btnPlayPause.setText("鈴� Pausar")
        ctx.asyncSpeak("Reproduciendo")
    end
end

btnGuardarDesc.onClick = function()
    if not audio_actual or not File(audio_actual).exists() then
        ctx.asyncSpeak("No hay audio"); return
    end
    local n = tostring(File(audio_actual).getName())
    if copiarArchivo(audio_actual, storage .. "/Download/" .. n) then
        tvEstado.setText("馃捑 Guardado en Descargas")
        ctx.asyncSpeak("Guardado en Descargas")
    else
        ctx.asyncSpeak("Error al guardar")
    end
end

btnCompartirUlt.onClick = function()
    if not audio_actual or not File(audio_actual).exists() then
        ctx.asyncSpeak("No hay audio"); return
    end
    compartirAudio(audio_actual)
end

btnVideoUlt.onClick = function()
    if not audio_actual or not File(audio_actual).exists() then
        ctx.asyncSpeak("No hay audio para convertir"); return
    end
    local nombreBase = tostring(File(audio_actual).getName()):gsub("%.wav$", "")
    local destino = audio_dir .. "/" .. nombreBase .. ".mp4"
    tvEstado.setText("馃幀 Convirtiendo a MP4, espera...")
    ctx.asyncSpeak("Convirtiendo a video, esto puede tardar un momento")
    local ok, resultado = convertirWAVaMP4(audio_actual, destino, tvEstado)
    if ok then
        tvEstado.setText("鉁� Video listo: " .. nombreBase .. ".mp4")
        ctx.asyncSpeak("Video generado correctamente")
    else
        tvEstado.setText("鉂� Fall贸: " .. tostring(resultado))
        ctx.asyncSpeak("La conversi贸n a video fall贸. " .. tostring(resultado))
    end
end

-- ============================================================================
-- BIBLIOTECA
-- ============================================================================

renderizarBiblioteca = function()
    contenedorAudios.removeAllViews()
    seleccionados = {}
    btnUnir.setVisibility(View.GONE)

    local audios = listarAudios()
    if #audios == 0 then
        local tv = TextView(ctx)
        tv.setText("Sin audios todav铆a.")
        tv.setTextColor(0xFF888888)
        tv.setGravity(Gravity.CENTER)
        tv.setPadding(10, 30, 10, 10)
        contenedorAudios.addView(tv)
        tvInfoBib.setText("Sin audios generados")
        return
    end

    tvInfoBib.setText(#audios .. " audio(s)  鈥�  鈽� para seleccionar y unir")

    for _, audio in ipairs(audios) do
        local item = LinearLayout(ctx)
        item.setOrientation(1)
        item.setBackgroundColor(0xFF1A1A2E)
        item.setPadding(8, 8, 8, 8)
        local pItem = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT)
        pItem.setMargins(0, 0, 0, 8)

        local tvN = TextView(ctx)
        tvN.setText("馃幍  " .. audio.nombre .. "  (" .. formatSize(audio.size) .. ")")
        tvN.setTextColor(0xFFE0E0E0)
        tvN.setTextSize(13)
        tvN.setPadding(4, 2, 4, 6)
        item.addView(tvN)

        local fila = LinearLayout(ctx)
        fila.setOrientation(0)

        local function crearBtn(label, bgColor, cb)
            local b = Button(ctx)
            b.setText(label)
            b.setTextSize(10)
            b.setTextColor(0xFFFFFFFF)
            b.setBackgroundColor(bgColor)
            b.setPadding(4, 4, 4, 4)
            local p = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT)
            p.weight = 1
            p.setMargins(2, 0, 2, 0)
            b.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {onClick = function(v) if cb then cb() end end}))
            fila.addView(b, p)
            return b
        end

        local auPath   = audio.path
        local auNombre = audio.nombre

        crearBtn("鈻�", 0xFF065F46, function()
            liberarPlayer()
            reproducirAudio(auPath, nil)
            tvInfoBib.setText("鈻� " .. auNombre)
        end)

        crearBtn("鈴�", 0xFF333333, function()
            liberarPlayer()
            ctx.asyncSpeak("Detenido")
        end)

        crearBtn("馃棏", 0xFFB71C1C, function()
            local dlgConf = LuaDialog(ctx)
            dlgConf.setTitle("Eliminar")
            dlgConf.setMessage("驴Eliminar " .. auNombre .. "?")
            dlgConf.setPositiveButton("S铆", function()
                File(auPath).delete()
                ctx.asyncSpeak("Eliminado")
                renderizarBiblioteca()
            end)
            dlgConf.setNegativeButton("No", nil)
            dlgConf.show()
        end)

        crearBtn("馃摛", 0xFF4A1942, function()
            compartirAudio(auPath)
        end)

        crearBtn("馃捑", 0xFF1E3A5F, function()
            if copiarArchivo(auPath, storage .. "/Download/" .. auNombre) then
                ctx.asyncSpeak("Guardado en Descargas")
            else
                ctx.asyncSpeak("Error al guardar")
            end
        end)

        crearBtn("馃幀", 0xFF78350F, function()
            local nombreBase = auNombre:gsub("%.wav$", "")
            local destino = audio_dir .. "/" .. nombreBase .. ".mp4"
            tvInfoBib.setText("馃幀 Convirtiendo " .. auNombre .. " a MP4...")
            ctx.asyncSpeak("Convirtiendo a video, esto puede tardar")
            local ok, resultado = convertirWAVaMP4(auPath, destino, tvInfoBib)
            if ok then
                tvInfoBib.setText("鉁� Video listo: " .. nombreBase .. ".mp4")
                ctx.asyncSpeak("Video generado correctamente")
            else
                tvInfoBib.setText("鉂� Fall贸: " .. tostring(resultado))
                ctx.asyncSpeak("La conversi贸n a video fall贸. " .. tostring(resultado))
            end
        end)

        local btnSel = crearBtn("鈽�", 0xFF2D2D2D, nil)
        -- Reasignar listener con setOnClickListener para bot贸n din谩mico
        btnSel.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
            onClick = function(v)
                if seleccionados[auPath] then
                    seleccionados[auPath] = nil
                    btnSel.setText("鈽�")
                    btnSel.setBackgroundColor(0xFF2D2D2D)
                else
                    seleccionados[auPath] = true
                    btnSel.setText("鈽�")
                    btnSel.setBackgroundColor(0xFF7C3AED)
                end
                local n = 0
                for _ in pairs(seleccionados) do n = n + 1 end
                btnUnir.setVisibility(n >= 2 and View.VISIBLE or View.GONE)
                tvInfoBib.setText(n >= 2 and (n .. " seleccionados") or (n == 1 and "Selecciona otro" or "鈽� para seleccionar"))
            end
        }))

        item.addView(fila)
        contenedorAudios.addView(item, pItem)
    end
end

btnRefrescar.onClick = function()
    renderizarBiblioteca()
    ctx.asyncSpeak("Actualizado")
end

btnUnir.onClick = function()
    local paths = {}
    for p in pairs(seleccionados) do table.insert(paths, p) end
    if #paths < 2 then ctx.asyncSpeak("Selecciona al menos 2"); return end
    table.sort(paths)
    local out = audio_dir .. "/union_" .. os.time() .. ".wav"
    local ok, err = unirAudios(paths, out)
    if ok then
        audio_actual = out
        ctx.asyncSpeak("Audios unidos")
        seleccionados = {}
        renderizarBiblioteca()
        reproducirAudio(out, nil)
    elseif err == "formato_distinto" then
        tvInfoBib.setText("鉂� No se puede unir: los audios tienen formatos distintos")
        ctx.asyncSpeak("No se puede unir. Los audios tienen formatos de audio distintos.")
    elseif err == "archivo_invalido" then
        tvInfoBib.setText("鉂� Uno de los archivos no es un WAV v谩lido")
        ctx.asyncSpeak("Uno de los archivos seleccionados no es un audio v谩lido")
    else
        ctx.asyncSpeak("Error al unir")
    end
end

-- ============================================================================
-- AJUSTES
-- ============================================================================

local function ajustar(campo, tv, paso, mn, mx)
    local v = math.max(mn, math.min(mx, math.floor((cfg[campo] + paso) * 100 + 0.5) / 100))
    cfg[campo] = v
    tv.setText(string.format("%.2f", v))
    ctx.asyncSpeak(string.format("%.2f", v))
end

btnEstMenos.onClick = function() ajustar("stability",  tvEstVal, -0.05, 0, 1) end
btnEstMas.onClick   = function() ajustar("stability",  tvEstVal,  0.05, 0, 1) end
btnSimMenos.onClick = function() ajustar("similarity", tvSimVal, -0.05, 0, 1) end
btnSimMas.onClick   = function() ajustar("similarity", tvSimVal,  0.05, 0, 1) end
btnStyMenos.onClick = function() ajustar("style",      tvStyVal, -0.05, 0, 1) end
btnStyMas.onClick   = function() ajustar("style",      tvStyVal,  0.05, 0, 1) end

btnBoost.onClick = function()
    cfg.boost = not cfg.boost
    btnBoost.setText(cfg.boost and "鉁� Speaker boost: ON" or "鉂� Speaker boost: OFF")
    btnBoost.setBackgroundColor(cfg.boost and 0xFF065F46 or 0xFF333333)
    ctx.asyncSpeak(cfg.boost and "Boost activado" or "Boost desactivado")
end

btnModelo.onClick = function()
    cfg.modelo = cfg.modelo == "eleven_multilingual_v2" and "eleven_turbo_v2_5" or "eleven_multilingual_v2"
    btnModelo.setText("馃 " .. (cfg.modelo == "eleven_turbo_v2_5" and "Turbo v2.5" or "Multiling眉e v2"))
    ctx.asyncSpeak("Modelo: " .. (cfg.modelo == "eleven_turbo_v2_5" and "Turbo" or "Multiling眉e"))
end

btnGuardarCfg.onClick = function()
    guardarCfg()
    ctx.asyncSpeak("Configuraci贸n guardada")
    tvEstado.setText("鉁� Configuraci贸n guardada")
end

-- ============================================================================
-- CERRAR
-- ============================================================================

btnCerrar.onClick = function()
    liberarPlayer()
    if tts_obj then pcall(function() tts_obj.shutdown() end) end
    guardarCfg()
    dlg.dismiss()
end

-- ============================================================================
-- MOSTRAR
-- ============================================================================

dlg = LuaDialog(ctx)
dlg.setTitle("馃帣锔� Estudio de Voz")
dlg.setView(view)
dlg.setCancelable(true)
dlg.show()

ctx.asyncSpeak("Estudio de voz abierto")

return true