require('dotenv').config()
const app = require('./app') // Aquí ya vienen cargadas todas las rutas
const PORT = process.env.PORT || 3000
const cron = require('node-cron')

// Importaciones de Jobs y Controladores para las tareas automaticas
const { syncEstaciones } = require('./jobs/syncCNE')
const { syncDescuentos } = require('./jobs/syncDescuentos')
const { verificarAlertas } = require('./controllers/alertasController')
const { syncVehiculos } = require('./jobs/syncVehiculos')

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Servidor CargApp corriendo en http://localhost:${PORT}`)
  
  // Función asíncrona para manejar el encendido seguro
  const inicializarServicios = async () => {
    try {
      console.log("[SISTEMA] Esperando estabilización de servicios...");
      
      // 1. Sincronizar Estaciones de la CNE y luego alertas
      console.log("[SISTEMA] Iniciando sync CNE...");
      await syncEstaciones();
      await verificarAlertas();
      
      // 2. Sincronizar Descuentos de forma segura
      console.log("[SISTEMA] Iniciando sync Descuentos...");
      await syncDescuentos();
      
      console.log("[SISTEMA] Sincronizaciones iniciales completadas con éxito.");
    } catch (err) {
      console.error("[SISTEMA] Error crítico en la inicialización:", err);
    }
  };

  // Le damos 5 segundos de colchón a MariaDB para que despierte tras un reinicio
  setTimeout(inicializarServicios, 5000);
})
