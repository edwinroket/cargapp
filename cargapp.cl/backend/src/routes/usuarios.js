const router     = require('express').Router()
const controller = require('../controllers/usuariosController')
const { verificarToken } = require('../middleware/auth')

router.post('/registro', controller.registro)
router.post('/login',    controller.login)

router.put('/perfil', verificarToken, controller.actualizarPerfil);

router.get('/perfil',    verificarToken, controller.getPerfil)
router.put('/perfil',    verificarToken, controller.actualizarPerfil)
router.get('/regiones',  controller.getRegiones)
router.get('/regiones/:regionId/ciudades', controller.getCiudadesPorRegion)

module.exports = router