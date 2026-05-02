require('dotenv').config()
const app  = require('./app')
const PORT = process.env.PORT || 3000
const cron = require('node-cron')
const { syncEstaciones }  = require('./jobs/syncCNE')
const { verificarAlertas } = require('./controllers/alertasController')

app.listen(PORT, () => {
  console.log(`Servidor CargApp corriendo en http://localhost:${PORT}`)
  syncEstaciones().then(() => verificarAlertas())
})

// Sync todos los días a las 3am
cron.schedule('0 3 * * *', () => {
  console.log('Cron: iniciando sync diario...')
  syncEstaciones().then(() => verificarAlertas())
})