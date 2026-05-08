require('dotenv').config()
const express = require('express')
const cors    = require('cors')
const app     = express()

// 1. Importar las rutas una sola vez
const usuariosRoutes = require('./routes/usuarios')
const estacionesRoutes = require('./routes/estaciones')
const alertasRoutes = require('./routes/alertas')
const reportesRoutes = require('./routes/reportes')
const vehiculosRoutes = require('./routes/vehiculos')
const descuentosRoutes = require('./routes/descuentos')

// 2. Middlewares
app.use(cors())
app.use(express.json())

// 3. Registrar las rutas
app.use('/api/usuarios', usuariosRoutes)
app.use('/api/estaciones', estacionesRoutes)
app.use('/api/alertas', alertasRoutes)
app.use('/api/reportes', reportesRoutes)
app.use('/api/vehiculos', vehiculosRoutes)
app.use('/api/descuentos', descuentosRoutes)

app.get('/', (req, res) => {
  res.json({ mensaje: 'CargApp API funcionando', version: '1.0' })
})

module.exports = app