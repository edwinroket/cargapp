const pool = require('../models/db');

// Listar alertas del usuario
const getAlertas = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT 
        a.id, a.precio_umbral, a.radio_km, a.activa,
        a.latitud_usuario, a.longitud_usuario,
        a.ultima_notificacion, a.creado_en,
        tc.nombre AS combustible,
        e.nombre AS estacion, e.direccion AS estacion_direccion
      FROM alertas a
      JOIN tipos_combustible tc ON tc.id = a.tipo_combustible_id
      LEFT JOIN estaciones e ON e.id = a.estacion_id
      WHERE a.usuario_id = ?
      ORDER BY a.creado_en DESC
    `, [req.usuarioId]);

    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener alertas' });
  }
};

// NUEVA FUNCIÓN: Toggle Alerta (Activar/Desactivar)
const toggleAlerta = async (req, res) => {
  const { id } = req.params;
  const { activa } = req.body; // Espera 1 o 0

  try {
    const [result] = await pool.query(
      'UPDATE alertas SET activa = ? WHERE id = ? AND usuario_id = ?',
      [activa, id, req.usuarioId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Alerta no encontrada' });
    }

    res.json({ mensaje: `Alerta ${activa ? 'activada' : 'desactivada'}` });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al actualizar estado de la alerta' });
  }
};

// Crear alerta
const crearAlerta = async (req, res) => {
  const { tipo_combustible_id, precio_umbral, radio_km, latitud_usuario, longitud_usuario, estacion_id } = req.body;

  if (!tipo_combustible_id || !precio_umbral) {
    return res.status(400).json({ error: 'tipo_combustible_id y precio_umbral son requeridos' });
  }

  if (!req.esPremium) {
    const [activas] = await pool.query(
      'SELECT COUNT(*) as total FROM alertas WHERE usuario_id = ? AND activa = 1',
      [req.usuarioId]
    );
    if (activas[0].total >= 2) {
      return res.status(403).json({ error: 'Plan gratuito permite máximo 2 alertas. Actualiza a Premium.' });
    }
  }

  try {
    const [result] = await pool.query(`
      INSERT INTO alertas 
        (usuario_id, tipo_combustible_id, precio_umbral, radio_km, latitud_usuario, longitud_usuario, estacion_id, activa)
      VALUES (?, ?, ?, ?, ?, ?, ?, 1)
    `, [
      req.usuarioId,
      tipo_combustible_id,
      precio_umbral,
      radio_km || 5,
      latitud_usuario || null,
      longitud_usuario || null,
      estacion_id || null
    ]);

    res.status(201).json({ mensaje: 'Alerta creada', id: result.insertId });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al crear alerta' });
  }
};

// Exportar funciones
module.exports = { crearAlerta, getAlertas, toggleAlerta };