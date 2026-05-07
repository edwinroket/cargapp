require('dotenv').config()
const express = require('express')
const cors    = require('cors')
const app     = express()

require('./models/db')

app.use(cors())
app.use(express.json())

//rutas
app.use('/api/usuarios', require('./routes/usuarios'))
app.use('/api/estaciones', require('./routes/estaciones'))
app.use('/api/alertas', require('./routes/alertas'))
app.use('/api/reportes', require('./routes/reportes'))
app.use('/api/vehiculos', require('./routes/vehiculos'))
app.use('/api/descuentos', require('./routes/descuentos'))

app.get('/', (req, res) => {
  res.json({ mensaje: 'CargApp API funcionando', version: '1.0' })
})

module.exports = app