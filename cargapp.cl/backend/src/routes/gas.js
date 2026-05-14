const express = require('express');
const router = express.Router();
const gasController = require('../controllers/gasController');
const { verificarToken } = require('../middleware/auth');

router.get('/', verificarToken, gasController.getPreciosGas);

module.exports = router;