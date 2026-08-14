const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 8080;
const PLUGINS_DIR = path.join(__dirname, 'plugins');
const UPLOADS_DIR = path.join(__dirname, 'uploads');

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Asegurar que las carpetas existen
[PLUGINS_DIR, UPLOADS_DIR].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

// ==================== RUTAS DE DESCARGA ====================

// Ruta: Obtener catálogo de plugins disponibles
app.get('/catalog', (req, res) => {
  try {
    fs.readdir(PLUGINS_DIR, (err, files) => {
      if (err) {
        return res.status(500).json({ error: 'Error al leer la carpeta de plugins' });
      }

      const plugins = files
        .filter(file => file.endsWith('.lua'))
        .map(file => {
          const filepath = path.join(PLUGINS_DIR, file);
          const stats = fs.statSync(filepath);
          return {
            id: file.replace('.lua', ''),
            name: file.replace('.lua', '').replace(/-/g, ' ').replace(/_/g, ' '),
            file_name: file,
            size: stats.size,
            download_url: `http://localhost:${PORT}/download/${file}`
          };
        });

      res.json(plugins);
    });
  } catch (error) {
    console.error('Error en /catalog:', error);
    res.status(500).json({ error: 'Error al obtener catálogo' });
  }
});

// Ruta: Descargar un plugin específico
app.get('/download/:filename', (req, res) => {
  try {
    const filename = req.params.filename;
    
    // Validar que el archivo es .lua
    if (!filename.endsWith('.lua')) {
      return res.status(400).json({ error: 'Archivo inválido' });
    }

    const filepath = path.join(PLUGINS_DIR, filename);

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

// ==================== RUTAS DE SUBIDA ====================

// Ruta: Subir un plugin
app.post('/upload', express.raw({ type: 'application/octet-stream', limit: '50mb' }), (req, res) => {
  try {
    const filename = req.headers['x-filename'];
    const name = req.headers['x-name'];
    const description = req.headers['x-description'] || 'Sin descripción';
    const version = req.headers['x-version'] || '1.0.0';
    const author = req.headers['x-author'] || 'Anónimo';

    if (!filename || !filename.endsWith('.lua')) {
      return res.status(400).json({ error: 'Nombre de archivo inválido' });
    }

    if (!req.body || req.body.length === 0) {
      return res.status(400).json({ error: 'Archivo vacío' });
    }

    const filepath = path.join(PLUGINS_DIR, filename);

    // Guardar archivo
    fs.writeFileSync(filepath, req.body);

    // Actualizar catalog.json
    updateCatalog();

    res.json({
      success: true,
      message: 'Archivo subido exitosamente',
      file: filename,
      download_url: `http://localhost:${PORT}/download/${filename}`
    });
  } catch (error) {
    console.error('Error en /upload:', error);
    res.status(500).json({ error: 'Error al subir archivo' });
  }
});

// ==================== UTILIDADES ====================

// Función para actualizar catalog.json
function updateCatalog() {
  try {
    fs.readdir(PLUGINS_DIR, (err, files) => {
      if (err) {
        console.error('Error al leer plugins:', err);
        return;
      }

      const plugins = files
        .filter(file => file.endsWith('.lua'))
        .map(file => {
          const filepath = path.join(PLUGINS_DIR, file);
          const stats = fs.statSync(filepath);
          return {
            id: file.replace('.lua', ''),
            name: file.replace('.lua', '').replace(/-/g, ' ').replace(/_/g, ' '),
            file_name: file,
            size: stats.size,
            version: '1.0.0',
            author: 'Desconocido',
            description: 'Sin descripción',
            download_url: `http://localhost:${PORT}/download/${file}`
          };
        });

      const catalogPath = path.join(__dirname, 'catalog.json');
      fs.writeFileSync(catalogPath, JSON.stringify(plugins, null, 2));
      console.log(`✅ Catálogo actualizado: ${plugins.length} plugins`);
    });
  } catch (error) {
    console.error('Error al actualizar catálogo:', error);
  }
}

// Ruta: Información del servidor
app.get('/info', (req, res) => {
  res.json({
    nombre: 'Tienda Jieshuo - Servidor de Plugins',
    version: '2.0.0',
    estado: 'en línea',
    url_api: `http://localhost:${PORT}`,
    funcionalidades: ['Descargar plugins', 'Subir plugins', 'Actualizar catálogo']
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
  console.log(`🚀 Servidor Tienda Jieshuo corriendo en puerto ${PORT}`);
  console.log(`📡 URL del servidor: http://localhost:${PORT}`);
  console.log(`📂 Carpeta de plugins: ${PLUGINS_DIR}`);
  console.log(`✅ Endpoints disponibles:`);
  console.log(`   - GET /catalog - Obtener lista de plugins`);
  console.log(`   - GET /download/:filename - Descargar plugin`);
  console.log(`   - POST /upload - Subir plugin`);
  console.log(`   - GET /info - Información del servidor`);
  console.log(`   - GET /health - Estado del servidor`);
});

module.exports = app;
