const pool = require('../models/db')

const getCercanas = async (req, res) => {
  const { lat, lng, radio = 5, combustible } = req.query

  if (!lat || !lng) {
    return res.status(400).json({ error: 'Se requiere lat y lng' })
  }

  try {
    const [rows] = await pool.query(`
      SELECT 
        e.id, e.nombre, e.marca, e.direccion, e.comuna, e.region,
        e.latitud, e.longitud, e.horario, e.metodos_pago,
        e.tiene_bano, e.tiene_tienda, e.tiene_lubricentro,
        e.tiene_cajero, e.tiene_aire, e.tiene_lavado,
        ROUND(
          6371 * ACOS(
            COS(RADIANS(?)) * COS(RADIANS(e.latitud)) *
            COS(RADIANS(e.longitud) - RADIANS(?)) +
            SIN(RADIANS(?)) * SIN(RADIANS(e.latitud))
          ), 2
        ) AS distancia_km
      FROM estaciones e
      WHERE e.activa = 1
      HAVING distancia_km <= ?
      ORDER BY distancia_km ASC
      LIMIT 30
    `, [lat, lng, lat, radio])

    const estaciones = await Promise.all(rows.map(async (e) => {
      const [precios] = await pool.query(`
        SELECT 
          tc.nombre AS combustible,
          tc.categoria,
          hp.precio,
          hp.fecha_registro
        FROM historial_precios hp
        JOIN tipos_combustible tc ON tc.id = hp.tipo_combustible_id
        WHERE hp.estacion_id = ?
          AND hp.id = (
            SELECT MAX(id) FROM historial_precios
            WHERE estacion_id = ? AND tipo_combustible_id = hp.tipo_combustible_id
          )
        ORDER BY tc.categoria, tc.nombre
      `, [e.id, e.id])

      return { ...e, combustibles: precios }
    }))

    const resultado = combustible
      ? estaciones.filter(e => e.combustibles.some(c => c.combustible.includes(combustible)))
      : estaciones

    res.json({ total: resultado.length, estaciones: resultado })

  } catch (err) {
    console.error(err)
    res.status(500).json({ error: 'Error al obtener estaciones' })
  }
}

const getDetalle = async (req, res) => {
  const { id } = req.params

  try {
    const [estacion] = await pool.query(
      `SELECT * FROM estaciones WHERE id = ? AND activa = 1`, [id]
    )

    if (!estacion.length) {
      return res.status(404).json({ error: 'Estación no encontrada' })
    }

    // Últimos precios por combustible
    const [precios] = await pool.query(`
      SELECT 
        tc.nombre AS combustible,
        tc.categoria,
        hp.precio,
        hp.fecha_registro
      FROM historial_precios hp
      JOIN tipos_combustible tc ON tc.id = hp.tipo_combustible_id
      WHERE hp.estacion_id = ?
        AND hp.id = (
          SELECT MAX(id) FROM historial_precios
          WHERE estacion_id = ? AND tipo_combustible_id = hp.tipo_combustible_id
        )
      ORDER BY tc.categoria, tc.nombre
    `, [id, id])

    // Historial de cambios REALES (Para la lista del detalle)
    // Filtramos para obtener los últimos 15 cambios de precio
    const [historial] = await pool.query(`
      SELECT 
        tc.nombre AS combustible,
        hp.precio,
        hp.fecha_registro,
        hp.fuente
      FROM historial_precios hp
      JOIN tipos_combustible tc ON tc.id = hp.tipo_combustible_id
      WHERE hp.estacion_id = ?
      ORDER BY hp.fecha_registro DESC
      LIMIT 15
    `, [id])

    res.json({
      estacion: estacion[0],
      precios_actuales: precios,
      historial: historial
    })

  } catch (err) {
    console.error(err)
    res.status(500).json({ error: 'Error al obtener detalle' })
  }
}

const getTiposCombustible = async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT * FROM tipos_combustible WHERE activo = 1 ORDER BY categoria, nombre`
    )
    res.json(rows)
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener combustibles' })
  }
}

module.exports = { getCercanas, getDetalle, getTiposCombustible }