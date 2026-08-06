const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 8080;
const TEMAS_DIR = path.join(__dirname, 'temas');

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Asegurar que la carpeta de temas existe
if (!fs.existsSync(TEMAS_DIR)) {
  fs.mkdirSync(TEMAS_DIR, { recursive: true });
}

// Ruta: Obtener catálogo de temas disponibles
app.get('/catalog', (req, res) => {
  try {
    fs.readdir(TEMAS_DIR, (err, files) => {
      if (err) {
        return res.status(500).json({ error: 'Error al leer la carpeta de temas' });
      }

      const temas = files
        .filter(file => file.endsWith('.spk'))
        .map(file => ({
          name: file.replace('.spk', ''),
          file: file,
          size: fs.statSync(path.join(TEMAS_DIR, file)).size
        }));

      res.json(temas);
    });
  } catch (error) {
    console.error('Error en /catalog:', error);
    res.status(500).json({ error: 'Error al obtener catálogo' });
  }
});

// Ruta: Descargar un tema específico
app.get('/download/:filename', (req, res) => {
  try {
    const filename = req.params.filename;
    
    // Validar que el archivo existe y es .spk
    if (!filename.endsWith('.spk')) {
      return res.status(400).json({ error: 'Archivo inválido' });
    }

    const filepath = path.join(TEMAS_DIR, filename);

    // Verificar que el archivo existe
    if (!fs.existsSync(filepath)) {
      return res.status(404).json({ error: 'Archivo no encontrado' });
    }

    // Enviar el archivo
    res.download(filepath, filename, (err) => {
      if (err) {
        console.error('Error al descargar:', err);
      }
    });
  } catch (error) {
    console.error('Error en /download:', error);
    res.status(500).json({ error: 'Error al descargar archivo' });
  }
});

// Ruta: Información del servidor
app.get('/info', (req, res) => {
  res.json({
    nombre: 'La Mejor Tienda - Servidor SPK',
    version: '1.0.0',
    estado: 'en línea',
    url_api: `http://localhost:${PORT}`
  });
});

// Ruta: Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Manejo de errores 404
app.use((req, res) => {
  res.status(404).json({ error: 'Ruta no encontrada' });
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`🚀 Servidor de La Mejor Tienda corriendo en puerto ${PORT}`);
  console.log(`📡 URL del servidor: http://localhost:${PORT}`);
  console.log(`📂 Carpeta de temas: ${TEMAS_DIR}`);
  console.log(`✅ Endpoints disponibles:`);
  console.log(`   - GET /catalog - Obtener lista de temas`);
  console.log(`   - GET /download/:filename - Descargar tema`);
  console.log(`   - GET /info - Información del servidor`);
  console.log(`   - GET /health - Estado del servidor`);
});

module.exports = app;
