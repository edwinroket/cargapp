const router     = require('express').Router()
const controller = require('../controllers/usuariosController')
const { verificarToken } = require('../middleware/auth')

router.post('/registro', controller.registro)
router.post('/login',    controller.login)
router.get('/perfil',    verificarToken, controller.getPerfil)
router.put('/perfil',    verificarToken, controller.actualizarPerfil)

module.exports = router