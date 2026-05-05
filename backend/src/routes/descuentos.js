const router     = require('express').Router()
const controller = require('../controllers/descuentosController')

router.get('/', controller.getDescuentos)

module.exports = router
