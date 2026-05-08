const express = require('express');
const router = express.Router();
const alertasController = require('../controllers/alertasController');
const { verificarToken } = require('../middleware/auth'); // Cambiamos esto

// Listar alertas - Ahora usamos verificarToken directamente
router.get('/', verificarToken, alertasController.getAlertas);

// Crear alerta
router.post('/', verificarToken, alertasController.crearAlerta);

// Toggle (Switch)
router.put('/:id', verificarToken, alertasController.toggleAlerta);

module.exports = router;