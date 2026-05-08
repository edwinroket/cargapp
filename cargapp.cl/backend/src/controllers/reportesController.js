const pool = require('../models/db');

// Crear un nuevo reporte de precio
const crearReporte = async (req, res) => {
  const { estacion_id, tipo_combustible_id, precio_reportado } = req.body;
  try {
    const [reciente] = await pool.query(`
      SELECT id FROM reportes
      WHERE usuario_id = ? AND estacion_id = ? AND tipo_combustible_id = ?
        AND creado_en >= DATE_SUB(NOW(), INTERVAL 2 HOUR)
    `, [req.usuarioId, estacion_id, tipo_combustible_id]);

    if (reciente.length) {
      return res.status(429).json({ error: 'Ya reportaste este combustible recientemente' });
    }

    const [result] = await pool.query(`
      INSERT INTO reportes (usuario_id, estacion_id, tipo_combustible_id, precio_reportado, estado)
      VALUES (?, ?, ?, ?, 'pendiente')
    `, [req.usuarioId, estacion_id, tipo_combustible_id, precio_reportado]);

    await pool.query('UPDATE usuarios SET puntos_reputacion = puntos_reputacion + 1 WHERE id = ?', [req.usuarioId]);

    res.status(201).json({ mensaje: 'Reporte enviado', id: result.insertId });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al crear reporte' });
  }
};

// Votar un reporte (Lógica de Desvoto/Reddit)
const votarReporte = async (req, res) => {
  const { voto } = req.body; 
  const reporteId = req.params.id;
  const usuarioId = req.usuarioId;

  try {
    const [reporte] = await pool.query('SELECT usuario_id FROM reportes WHERE id = ?', [reporteId]);
    
    if (!reporte.length) return res.status(404).json({ error: 'Reporte no encontrado' });
    if (reporte[0].usuario_id === usuarioId) {
      return res.status(403).json({ error: 'No puedes votar tu propio reporte' });
    }

    const [votoPrevio] = await pool.query(
      'SELECT voto FROM votos_reporte WHERE reporte_id = ? AND usuario_id = ?',
      [reporteId, usuarioId]
    );

    if (votoPrevio.length > 0 && votoPrevio[0].voto === voto) {
      await pool.query('DELETE FROM votos_reporte WHERE reporte_id = ? AND usuario_id = ?', [reporteId, usuarioId]);
    } else {
      await pool.query(`
        INSERT INTO votos_reporte (reporte_id, usuario_id, voto) 
        VALUES (?, ?, ?) 
        ON DUPLICATE KEY UPDATE voto = VALUES(voto)
      `, [reporteId, usuarioId, voto]);
    }

    await pool.query(`
      UPDATE reportes SET 
        votos_positivos = (SELECT COUNT(*) FROM votos_reporte WHERE reporte_id = ? AND voto = 'positivo'),
        votos_negativos = (SELECT COUNT(*) FROM votos_reporte WHERE reporte_id = ? AND voto = 'negativo')
      WHERE id = ?
    `, [reporteId, reporteId, reporteId]);

    const [actualizado] = await pool.query('SELECT votos_positivos FROM reportes WHERE id = ?', [reporteId]);
    if (actualizado[0].votos_positivos >= 3) {
      await pool.query("UPDATE reportes SET estado = 'verificado' WHERE id = ?", [reporteId]);
      await pool.query('UPDATE usuarios SET puntos_reputacion = puntos_reputacion + 5 WHERE id = ?', [reporte[0].usuario_id]);
    }

    res.json({ mensaje: 'Acción procesada correctamente' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al procesar voto' });
  }
};

// Obtener reportes cercanos para el feed
const getReportesCercanos = async (req, res) => {
  const { lat, lng, radio = 10 } = req.query;
  const usuarioId = req.usuarioId; 

  if (!lat || !lng || isNaN(lat) || isNaN(lng)) {
    return res.status(400).json({ error: 'Latitud y longitud válidas' });
  }

  try {
    const [rows] = await pool.query(`
      SELECT 
        r.*, 
        tc.nombre AS combustible, 
        IFNULL(CONCAT(e.direccion, ' (', e.marca, ')'), e.nombre) AS estacion_formateada, 
        u.nombre_completo AS usuario, 
        u.puntos_reputacion AS reputacion_usuario,
        (SELECT voto FROM votos_reporte WHERE reporte_id = r.id AND usuario_id = ?) AS mi_voto,
        (6371 * ACOS(
          LEAST(1, COS(RADIANS(?)) * COS(RADIANS(e.latitud)) * COS(RADIANS(e.longitud) - RADIANS(?)) + 
          SIN(RADIANS(?)) * SIN(RADIANS(e.latitud)))
        )) AS distancia_km
      FROM reportes r
      JOIN estaciones e ON e.id = r.estacion_id
      JOIN tipos_combustible tc ON tc.id = r.tipo_combustible_id
      JOIN usuarios u ON u.id = r.usuario_id
      WHERE r.estado != 'rechazado' 
        AND r.creado_en >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
      HAVING distancia_km <= ?
      ORDER BY r.creado_en DESC
    `, [usuarioId, parseFloat(lat), parseFloat(lng), parseFloat(lat), parseFloat(radio)]);
    
    res.json(rows);
  } catch (err) {
    console.error("ERROR SQL EN FEED:", err.message); 
    res.status(500).json({ error: 'Error al obtener feed' });
  }
};

const getReportesEstacion = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT r.*, tc.nombre AS combustible, u.nombre_completo AS usuario 
      FROM reportes r 
      JOIN tipos_combustible tc ON tc.id = r.tipo_combustible_id
      JOIN usuarios u ON u.id = r.usuario_id
      WHERE r.estacion_id = ? AND r.estado != 'rechazado'
    `, [req.params.estacion_id]);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al obtener reportes de estación' });
  }
};

module.exports = { crearReporte, votarReporte, getReportesCercanos, getReportesEstacion };