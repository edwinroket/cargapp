const pool = require('../models/db')

// Crear alerta
const crearAlerta = async (req, res) => {
  const { tipo_combustible_id, precio_umbral, radio_km, latitud_usuario, longitud_usuario, estacion_id } = req.body

  if (!tipo_combustible_id || !precio_umbral) {
    return res.status(400).json({ error: 'tipo_combustible_id y precio_umbral son requeridos' })
  }

  // Usuarios gratis máximo 2 alertas activas
  if (!req.esPremium) {
    const [activas] = await pool.query(
      'SELECT COUNT(*) as total FROM alertas WHERE usuario_id = ? AND activa = 1',
      [req.usuarioId]
    )
    if (activas[0].total >= 2) {
      return res.status(403).json({ error: 'Plan gratuito permite máximo 2 alertas. Actualiza a Premium.' })
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
    ])

    res.status(201).json({ mensaje: 'Alerta creada', id: result.insertId })

  } catch (err) {
    console.error(err)
    res.status(500).json({ error: 'Error al crear alerta' })
  }
}

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
    `, [req.usuarioId])

    res.json(rows)
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener alertas' })
  }
}

// Desactivar alerta
const desactivarAlerta = async (req, res) => {
  try {
    const [result] = await pool.query(
      'UPDATE alertas SET activa = 0 WHERE id = ? AND usuario_id = ?',
      [req.params.id, req.usuarioId]
    )

    if (!result.affectedRows) {
      return res.status(404).json({ error: 'Alerta no encontrada' })
    }

    res.json({ mensaje: 'Alerta desactivada' })
  } catch (err) {
    res.status(500).json({ error: 'Error al desactivar alerta' })
  }
}

// Verificar alertas — lo llama el cron job después de cada sync
const verificarAlertas = async () => {
  console.log('Verificando alertas...')
  try {
    const [alertas] = await pool.query(`
      SELECT a.*, tc.nombre AS combustible
      FROM alertas a
      JOIN tipos_combustible tc ON tc.id = a.tipo_combustible_id
      WHERE a.activa = 1
    `)

    let notificaciones = 0

    for (const alerta of alertas) {
      let query, params

      if (alerta.estacion_id) {
        // Alerta por estación específica
        query = `
          SELECT hp.precio, e.nombre, e.direccion
          FROM historial_precios hp
          JOIN estaciones e ON e.id = hp.estacion_id
          WHERE hp.estacion_id = ? AND hp.tipo_combustible_id = ?
          ORDER BY hp.fecha_registro DESC LIMIT 1
        `
        params = [alerta.estacion_id, alerta.tipo_combustible_id]
      } else {
        // Alerta por radio
        query = `
          SELECT hp.precio, e.nombre, e.direccion,
            (6371 * ACOS(
              COS(RADIANS(?)) * COS(RADIANS(e.latitud)) *
              COS(RADIANS(e.longitud) - RADIANS(?)) +
              SIN(RADIANS(?)) * SIN(RADIANS(e.latitud))
            )) AS distancia_km
          FROM historial_precios hp
          JOIN estaciones e ON e.id = hp.estacion_id
          WHERE hp.tipo_combustible_id = ?
            AND hp.id = (
              SELECT MAX(id) FROM historial_precios
              WHERE estacion_id = hp.estacion_id AND tipo_combustible_id = ?
            )
          HAVING distancia_km <= ?
          ORDER BY hp.precio ASC
          LIMIT 1
        `
        params = [
          alerta.latitud_usuario, alerta.longitud_usuario, alerta.latitud_usuario,
          alerta.tipo_combustible_id, alerta.tipo_combustible_id,
          alerta.radio_km
        ]
      }

      const [resultado] = await pool.query(query, params)
      if (!resultado.length) continue

      const precioActual = parseFloat(resultado[0].precio)
      if (precioActual <= alerta.precio_umbral) {
        console.log(`Alerta disparada: usuario ${alerta.usuario_id} — ${alerta.combustible} a $${precioActual} en ${resultado[0].nombre}`)

        // Actualizar última notificación
        await pool.query(
          'UPDATE alertas SET ultima_notificacion = NOW() WHERE id = ?',
          [alerta.id]
        )
        notificaciones++
        // TODO: enviar push notification con Firebase
      }
    }

    console.log(`Alertas verificadas: ${notificaciones} notificaciones disparadas`)
  } catch (err) {
    console.error('Error verificando alertas:', err.message)
  }
}

module.exports = { crearAlerta, getAlertas, desactivarAlerta, verificarAlertas }