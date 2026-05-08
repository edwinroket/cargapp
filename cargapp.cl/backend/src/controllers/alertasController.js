const pool = require('../models/db');

// Listar alertas del usuario
const getAlertas = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT a.id, a.precio_umbral, a.radio_km, a.activa,
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

// Toggle Alerta (El switch de la App)
const toggleAlerta = async (req, res) => {
  const { id } = req.params;
  const { activa } = req.body; 
  try {
    await pool.query(
      'UPDATE alertas SET activa = ? WHERE id = ? AND usuario_id = ?',
      [activa, id, req.usuarioId]
    );
    res.json({ mensaje: `Alerta ${activa ? 'activada' : 'desactivada'}` });
  } catch (err) {
    res.status(500).json({ error: 'Error al actualizar estado' });
  }
};

// Crear alerta
const crearAlerta = async (req, res) => {
  const { tipo_combustible_id, precio_umbral, radio_km, latitud_usuario, longitud_usuario, estacion_id } = req.body;
  try {
    const [result] = await pool.query(`
      INSERT INTO alertas (usuario_id, tipo_combustible_id, precio_umbral, radio_km, latitud_usuario, longitud_usuario, estacion_id, activa)
      VALUES (?, ?, ?, ?, ?, ?, ?, 1)
    `, [req.usuarioId, tipo_combustible_id, precio_umbral, radio_km || 5, latitud_usuario, longitud_usuario, estacion_id]);
    res.status(201).json({ mensaje: 'Alerta creada', id: result.insertId });
  } catch (err) {
    res.status(500).json({ error: 'Error al crear alerta' });
  }
};

// Función interna para el CRON JOB (verificar precios)
const verificarAlertas = async () => {
  console.log('--- [SISTEMA] Verificando alertas activas ---');
  try {
    const [alertas] = await pool.query(`
      SELECT a.*, tc.nombre AS combustible
      FROM alertas a
      JOIN tipos_combustible tc ON tc.id = a.tipo_combustible_id
      WHERE a.activa = 1
    `);

    for (const alerta of alertas) {
      const [resultado] = await pool.query(`
        SELECT hp.precio, e.nombre 
        FROM historial_precios hp
        JOIN estaciones e ON e.id = hp.estacion_id
        WHERE hp.tipo_combustible_id = ? AND hp.precio <= ?
        ORDER BY hp.fecha_registro DESC LIMIT 1
      `, [alerta.tipo_combustible_id, alerta.precio_umbral]);

      if (resultado.length > 0) {
        console.log(`¡Alerta disparada! Usuario ${alerta.usuario_id}: ${alerta.combustible} a $${resultado[0].precio}`);
        await pool.query('UPDATE alertas SET ultima_notificacion = NOW() WHERE id = ?', [alerta.id]);
      }
    }
    console.log('--- [SISTEMA] Fin de verificación ---');
  } catch (err) {
    console.error('Error en verificarAlertas:', err.message);
  }
};

module.exports = { crearAlerta, getAlertas, toggleAlerta, verificarAlertas };