require('dotenv').config()
const app = require('./app') // Aquí ya vienen cargadas todas las rutas
const PORT = process.env.PORT || 3000
const cron = require('node-cron')

// Importaciones de Jobs y Controladores para las tareas automaticas
const { syncEstaciones } = require('./jobs/syncCNE')
const { syncDescuentos } = require('./jobs/syncDescuentos')
const { verificarAlertas } = require('./controllers/alertasController')

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Servidor CargApp corriendo en http://localhost:${PORT}`)
  
  // Ejecución inicial de sincronización y alertas
  syncEstaciones()
    .then(() => verificarAlertas())
    .catch(err => console.error("Error en sync inicial:", err));
    
  syncDescuentos();
})

// Tarea programada: Sincronizar precios cada dia a las 3 AM
cron.schedule('0 3 * * *', () => {
  console.log('Cron: ejecutando actualización de precios diaria...');
  syncEstaciones().then(() => verificarAlertas())
})

// Tarea programada: Sincronizar descuentos cada lunes a las 4 AM
cron.schedule('0 4 * * 1', () => {
  console.log('Cron: ejecutando actualización de descuentos semanal...');
  syncDescuentos()
})