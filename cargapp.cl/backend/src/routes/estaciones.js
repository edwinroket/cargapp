const express = require('express');
const router = express.Router();
const controller = require('../controllers/estacionesController');

// 1. El mapa llama a la raíz '/' -> Ejecuta la función getMapa del controlador
router.get('/', controller.getMapa);

// 2. El buscador de reportes llama a '/cercanas' -> Ejecuta getCercanas del controlador
router.get('/cercanas', controller.getCercanas);

// 3. Detalle de una estación específica
router.get('/:id', controller.getDetalle);

// 4. Listado de tipos de combustible
router.get('/combustibles', controller.getTiposCombustible);

module.exports = router;