const router     = require('express').Router()
const controller = require('../controllers/estacionesController')

router.get('/',                  controller.getCercanas)
router.get('/combustibles',      controller.getTiposCombustible)
router.get('/:id',               controller.getDetalle)

module.exports = router