require('dotenv').config()
const app  = require('./app')
const PORT = process.env.PORT || 3000
const cron = require('node-cron')
const { syncEstaciones }   = require('./jobs/syncCNE')
const { verificarAlertas } = require('./controllers/alertasController')
const { syncDescuentos }   = require('./jobs/syncDescuentos')
const descuentosRoutes = require('./routes/descuentos');

app.use('/api/descuentos', descuentosRoutes);

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Servidor CargApp corriendo en http://localhost:${PORT}`)
  syncEstaciones().then(() => verificarAlertas())
  syncDescuentos()
})

// Precios cada día a las 3am
cron.schedule('0 3 * * *', () => {
  console.log('Cron: sync diario de precios...')
  syncEstaciones().then(() => verificarAlertas())
})

// Descuentos cada lunes a las 4am
cron.schedule('0 4 * * 1', () => {
  console.log('Cron: sync semanal de descuentos...')
  syncDescuentos()
})