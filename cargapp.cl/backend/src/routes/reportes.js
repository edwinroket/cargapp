const express = require('express');
const router = express.Router();
const controller = require('../controllers/reportesController');
const { verificarToken } = require('../middleware/auth');

// 1. Ver reportes cercanos (Radio GPS) - Es un GET
router.get('/cercanos', controller.getReportesCercanos);

// 2. Ver reportes de una estación específica
router.get('/estacion/:estacion_id', controller.getReportesEstacion);

// 3. Crear reporte - Requiere Login
router.post('/', verificarToken, controller.crearReporte);

// 4. Votar reporte - Requiere Login
router.post('/:id/votar', verificarToken, controller.votarReporte);

module.exports = router;