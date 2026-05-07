const router     = require('express').Router()
const controller = require('../controllers/alertasController')
const { verificarToken } = require('../middleware/auth')

router.use(verificarToken)

router.post('/',        controller.crearAlerta)
router.get('/',         controller.getAlertas)
router.delete('/:id',   controller.desactivarAlerta)

module.exports = router