const router     = require('express').Router()
const controller = require('../controllers/reportesController')
const { verificarToken } = require('../middleware/auth')

// Ver reportes de una estación — público
router.get('/estacion/:estacion_id', controller.getReportesEstacion)

// Crear y votar — requiere login
router.post('/',            verificarToken, controller.crearReporte)
router.post('/:id/votar',   verificarToken, controller.votarReporte)

module.exports = router