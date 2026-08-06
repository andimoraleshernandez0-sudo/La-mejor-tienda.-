# La Mejor Tienda 🎵

Servidor Node.js + Página Web para descargar temas SPK. Compatible con AndroLua.

---

## 📋 Características

### Servidor SPK
- ✅ Servidor Express.js
- ✅ Compatible con cliente AndroLua (Lua)
- ✅ Descarga de archivos .spk
- ✅ Catálogo automático de temas
- ✅ CORS habilitado
- ✅ Health check

### Página Web
- ✅ Interfaz moderna y responsiva
- ✅ Contador interactivo de clics
- ✅ Persistencia de datos con localStorage
- ✅ Diseño adaptable (mobile-first)
- ✅ Animaciones suaves

---

## 🎨 Tecnologías

- **Frontend:** HTML5, CSS3, JavaScript Vanilla
- **Backend:** Node.js, Express.js
- **API:** REST
- **Cliente:** AndroLua (Lua)

---

## 📁 Estructura del Proyecto

```
La-mejor-tienda.-/
├── server.js           # Servidor Node.js principal
├── package.json        # Dependencias de Node.js
├── .env                # Variables de entorno
├── .gitignore          # Archivos ignorados
├── temas/              # Carpeta con archivos .spk
│   ├── tema1.spk
│   ├── tema2.spk
│   └── ...
├── index.html          # Página web principal
├── style.css           # Estilos de la página web
├── script.js           # Lógica JavaScript de la página
└── README.md           # Este archivo
```

---

## 🚀 Instalación Local

### Requisitos
- Node.js 18.x o superior
- npm

### Pasos

1. **Clona el repositorio**
```bash
git clone https://github.com/andimoraleshernandez0-sudo/La-mejor-tienda.-
cd La-mejor-tienda.-
```

2. **Instala dependencias**
```bash
npm install
```

3. **Agrega tus archivos .spk**
```bash
# Crea la carpeta si no existe
mkdir temas

# Copia tus archivos .spk aquí
# (Descárgalos del ZIP de Google Drive)
```

4. **Inicia el servidor**
```bash
npm start
```

5. **Verifica que funciona**
```
Servidor: http://localhost:8080
Página web: http://localhost:8080/
Catálogo: http://localhost:8080/catalog
```

---

## 📡 Endpoints de la API

### 1. Obtener Catálogo de Temas
```
GET /catalog
```

**Respuesta:**
```json
[
  {
    "name": "Tema 1",
    "file": "tema1.spk",
    "size": 2048576
  }
]
```

### 2. Descargar Tema
```
GET /download/tema1.spk
```

Descarga el archivo `.spk` especificado.

### 3. Información del Servidor
```
GET /info
```

**Respuesta:**
```json
{
  "nombre": "La Mejor Tienda - Servidor SPK",
  "version": "1.0.0",
  "estado": "en línea"
}
```

### 4. Health Check
```
GET /health
```

**Respuesta:**
```json
{
  "status": "ok"
}
```

---

## 📱 Uso con AndroLua

En tu cliente Lua (AndroLua), configura la URL del servidor:

```lua
local SERVER_URL = "http://tu-servidor.com:8080"
-- o si es local:
local SERVER_URL = "http://192.168.x.x:8080"
```

El cliente automáticamente:
1. Consulta `/catalog`
2. Muestra los temas disponibles
3. Descarga desde `/download/:filename`
4. Descomprime en `/sdcard/Jieshuo/sound/`

---

## 🌐 Despliegue en la Nube

### Opción 1: Replit (GRATIS) ⭐ Recomendado
1. Ve a https://replit.com
2. Crea un nuevo proyecto desde GitHub
3. Selecciona este repositorio
4. Elige "Node.js"
5. Ejecuta `npm install && npm start`
6. Tu URL pública: `https://tu-replit.replit.dev`

### Opción 2: Railway (GRATIS con créditos)
1. Ve a https://railway.app
2. Conecta tu GitHub
3. Importa este repositorio
4. Automáticamente detectará `package.json`
5. Se deployará automáticamente

### Opción 3: Heroku (Requiere tarjeta)
1. Ve a https://heroku.com
2. Crea una nueva app
3. Conecta tu repositorio GitHub
4. Deploy automático

### Opción 4: GitHub Pages (Solo página web, SIN servidor)
1. Ve a Settings del repositorio
2. En "Pages", selecciona "Deploy from a branch"
3. Selecciona rama `main` y carpeta `/ (root)`
4. Tu sitio: `https://andimoraleshernandez0-sudo.github.io/La-mejor-tienda.-/`

---

## 🔧 Configuración

### Variables de entorno (.env)
```
PORT=8080
NODE_ENV=development
```

### Agregar más temas SPK

1. Descarga los archivos `.spk` del ZIP
2. Colócalos en la carpeta `/temas/`
3. Reinicia el servidor
4. Automáticamente aparecerán en `/catalog`

---

## 📱 Funcionalidades de la Página Web

- **Contador:** Haz clic en el botón "¡Tócame!" para incrementar
- **Reiniciar:** El botón "Reiniciar" devuelve el contador a 0
- **Persistencia:** Tu contador se guarda incluso si cierras el navegador

---

## 🐛 Solución de Problemas

### "Error al conectar con la tienda" (en AndroLua)
- Verifica que el servidor esté corriendo
- Comprueba que la URL es correcta
- Revisa el firewall/router
- Si es local, usa tu IP: `http://192.168.x.x:8080`

### "No se encontraron temas"
- Asegúrate de agregar archivos `.spk` en la carpeta `/temas/`
- Reinicia el servidor después de agregar archivos
- Verifica que el nombre termine en `.spk`

### "Error al extraer el archivo SPK" (en AndroLua)
- Verifica que el archivo `.spk` es válido (es un ZIP)
- Comprueba permisos en Android
- Intenta con otro tema

### Puerto 8080 ya está en uso
```bash
# Cambia el puerto en .env
PORT=3000

# O mata el proceso que usa el puerto
lsof -i :8080  # Ver qué usa el puerto
kill -9 <PID>  # Matar el proceso
```

---

## 💡 Cómo personalizar

Edita estos archivos para cambiar:

**Página Web:**
- `index.html` - Contenido de la página
- `style.css` - Colores, fuentes, diseño
- `script.js` - Lógica y funcionalidades

**Servidor:**
- `server.js` - Rutas y lógica del servidor
- `package.json` - Dependencias

---

## 📝 Próximas Mejoras

- [ ] Base de datos para almacenar metadatos de temas
- [ ] Upload de temas desde la web
- [ ] Sistema de autenticación
- [ ] Analytics de descargas
- [ ] Interfaz web para gestionar temas

---

## 👤 Autor

Creado por: @andimoraleshernandez0-sudo

## 📄 Licencia

MIT

---

**¿Necesitas ayuda?** Abre un issue o contacta al desarrollador. 🚀
