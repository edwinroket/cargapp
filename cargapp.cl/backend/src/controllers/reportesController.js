const pool = require('../models/db')

// Crear reporte de precio
const crearReporte = async (req, res) => {
  const { estacion_id, tipo_combustible_id, precio_reportado } = req.body

  if (!estacion_id || !tipo_combustible_id || !precio_reportado) {
    return res.status(400).json({ error: 'estacion_id, tipo_combustible_id y precio_reportado son requeridos' })
  }

  // Validar que el precio sea razonable (entre $500 y $5000 por litro)
  const precio = parseFloat(precio_reportado)
  if (precio < 500 || precio > 5000) {
    return res.status(400).json({ error: 'Precio fuera de rango válido ($500 - $5000)' })
  }

  try {
    // Verificar que la estación existe
    const [estacion] = await pool.query(
      'SELECT id FROM estaciones WHERE id = ? AND activa = 1', [estacion_id]
    )
    if (!estacion.length) {
      return res.status(404).json({ error: 'Estación no encontrada' })
    }

    // Evitar spam: un reporte por usuario por estación por combustible cada 2 horas
    const [reciente] = await pool.query(`
      SELECT id FROM reportes
      WHERE usuario_id = ? AND estacion_id = ? AND tipo_combustible_id = ?
        AND creado_en >= DATE_SUB(NOW(), INTERVAL 2 HOUR)
    `, [req.usuarioId, estacion_id, tipo_combustible_id])

    if (reciente.length) {
      return res.status(429).json({ error: 'Ya reportaste un precio en esta estación hace menos de 2 horas' })
    }

    const [result] = await pool.query(`
      INSERT INTO reportes (usuario_id, estacion_id, tipo_combustible_id, precio_reportado, estado)
      VALUES (?, ?, ?, ?, 'pendiente')
    `, [req.usuarioId, estacion_id, tipo_combustible_id, precio])

    // Sumar punto de reputación al usuario por reportar
    await pool.query(
      'UPDATE usuarios SET puntos_reputacion = puntos_reputacion + 1 WHERE id = ?',
      [req.usuarioId]
    )

    res.status(201).json({ mensaje: 'Reporte enviado, gracias por contribuir', id: result.insertId })

  } catch (err) {
    console.error(err)
    res.status(500).json({ error: 'Error al crear reporte' })
  }
}

// Votar un reporte (pulgar arriba o abajo)
const votarReporte = async (req, res) => {
  const { voto } = req.body // 'positivo' o 'negativo'

  if (!['positivo', 'negativo'].includes(voto)) {
    return res.status(400).json({ error: 'voto debe ser positivo o negativo' })
  }

  try {
    const [reporte] = await pool.query(
      'SELECT * FROM reportes WHERE id = ?', [req.params.id]
    )
    if (!reporte.length) {
      return res.status(404).json({ error: 'Reporte no encontrado' })
    }

    // No puedes votar tu propio reporte
    if (reporte[0].usuario_id === req.usuarioId) {
      return res.status(403).json({ error: 'No puedes votar tu propio reporte' })
    }

    // Verificar si ya votó
    const [yaVoto] = await pool.query(
      'SELECT id FROM votos_reporte WHERE reporte_id = ? AND usuario_id = ?',
      [req.params.id, req.usuarioId]
    )
    if (yaVoto.length) {
      return res.status(409).json({ error: 'Ya votaste este reporte' })
    }

    // Registrar voto
    await pool.query(
      'INSERT INTO votos_reporte (reporte_id, usuario_id, voto) VALUES (?, ?, ?)',
      [req.params.id, req.usuarioId, voto]
    )

    // Actualizar contadores
    if (voto === 'positivo') {
      await pool.query(
        'UPDATE reportes SET votos_positivos = votos_positivos + 1 WHERE id = ?',
        [req.params.id]
      )
    } else {
      await pool.query(
        'UPDATE reportes SET votos_negativos = votos_negativos + 1 WHERE id = ?',
        [req.params.id]
      )
    }

    // Verificar si el reporte se verifica o rechaza automáticamente
    const [actualizado] = await pool.query(
      'SELECT votos_positivos, votos_negativos FROM reportes WHERE id = ?',
      [req.params.id]
    )
    const { votos_positivos, votos_negativos } = actualizado[0]

    if (votos_positivos >= 3) {
      // Verificado — actualizar precio en historial
      await pool.query(
        'UPDATE reportes SET estado = ? WHERE id = ?',
        ['verificado', req.params.id]
      )
      await pool.query(`
        INSERT INTO historial_precios (estacion_id, tipo_combustible_id, precio, fecha_registro, fuente)
        VALUES (?, ?, ?, NOW(), 'reporte_usuario')
      `, [reporte[0].estacion_id, reporte[0].tipo_combustible_id, reporte[0].precio_reportado])

      // Bonus de reputación al autor del reporte verificado
      await pool.query(
        'UPDATE usuarios SET puntos_reputacion = puntos_reputacion + 5 WHERE id = ?',
        [reporte[0].usuario_id]
      )
    } else if (votos_negativos >= 3) {
      await pool.query(
        'UPDATE reportes SET estado = ? WHERE id = ?',
        ['rechazado', req.params.id]
      )
      // Quitar punto de reputación por reporte rechazado
      await pool.query(
        'UPDATE usuarios SET puntos_reputacion = puntos_reputacion - 1 WHERE id = ?',
        [reporte[0].usuario_id]
      )
    }

    res.json({ mensaje: `Voto ${voto} registrado` })

  } catch (err) {
    console.error(err)
    res.status(500).json({ error: 'Error al votar' })
  }
}

// Obtener reportes de una estación
const getReportesEstacion = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT 
        r.id, r.precio_reportado, r.votos_positivos, r.votos_negativos,
        r.estado, r.creado_en,
        tc.nombre AS combustible,
        u.nombre_completo AS usuario,
        u.puntos_reputacion AS reputacion_usuario
      FROM reportes r
      JOIN tipos_combustible tc ON tc.id = r.tipo_combustible_id
      JOIN usuarios u ON u.id = r.usuario_id
      WHERE r.estacion_id = ? AND r.estado != 'rechazado'
      ORDER BY r.creado_en DESC
      LIMIT 20
    `, [req.params.estacion_id])

    res.json(rows)
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener reportes' })
  }
}

module.exports = { crearReporte, votarReporte, getReportesEstacion }