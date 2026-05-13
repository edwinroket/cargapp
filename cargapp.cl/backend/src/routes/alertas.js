const express = require('express');
const router = express.Router();
const alertasController = require('../controllers/alertasController');
const { verificarToken } = require('../middleware/auth'); 

// Listar alertas
router.get('/', verificarToken, alertasController.getAlertas);

// Crear alerta
router.post('/', verificarToken, alertasController.crearAlerta);

// Toggle (Switch)
router.put('/:id', verificarToken, alertasController.toggleAlerta);

// Eliminar alerta 
router.delete('/:id', verificarToken, alertasController.eliminarAlerta);

module.exports = router;