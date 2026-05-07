const router     = require('express').Router()
const controller = require('../controllers/vehiculosController')
const { verificarToken } = require('../middleware/auth')

router.use(verificarToken)

router.post('/',            controller.crearVehiculo)
router.get('/',             controller.getVehiculos)
router.get('/costo',        controller.calcularCosto)
router.get('/modelos',      controller.getModelosVehiculo)
router.post('/modelos',     controller.crearModeloVehiculo)
router.get('/modelos/:id',  controller.getModeloVehiculo)
router.get('/:id',          controller.getVehiculo)
router.delete('/:id',       controller.eliminarVehiculo)

module.exports = router