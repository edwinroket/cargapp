const router     = require('express').Router()
const controller = require('../controllers/vehiculosController')
const { verificarToken } = require('../middleware/auth')

router.use(verificarToken)

router.post('/',            controller.crearVehiculo)
router.get('/',             controller.getVehiculos)
router.delete('/:id',       controller.eliminarVehiculo)
router.get('/costo',        controller.calcularCosto)

module.exports = router