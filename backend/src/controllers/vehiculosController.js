const pool = require('../models/db')

// Agregar vehículo
const crearVehiculo = async (req, res) => {
  const {
    modelo_id,
    alias,
    marca_manual,
    modelo_manual,
    anio_manual,
    rendimiento_km_l,
    tipo_combustible_id,
    es_principal
  } = req.body

  if (!rendimiento_km_l || !tipo_combustible_id) {
    return res.status(400).json({ error: 'rendimiento_km_l y tipo_combustible_id son requeridos' })
  }

  try {
    // Si es principal, desmarcar los otros
    if (es_principal) {
      await pool.query(
        'UPDATE vehiculos SET es_principal = 0 WHERE usuario_id = ?',
        [req.usuarioId]
      )
    }

    const [result] = await pool.query(`
      INSERT INTO vehiculos
        (usuario_id, modelo_id, alias, marca_manual, modelo_manual, anio_manual,
         rendimiento_km_l, tipo_combustible_id, es_principal)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [
      req.usuarioId,
      modelo_id     || null,
      alias         || null,
      marca_manual  || null,
      modelo_manual || null,
      anio_manual   || null,
      rendimiento_km_l,
      tipo_combustible_id,
      es_principal ? 1 : 0
    ])

    res.status(201).json({ mensaje: 'Vehículo agregado', id: result.insertId })

  } catch (err) {
    console.error(err)
    res.status(500).json({ error: 'Error al crear vehículo' })
  }
}

// Listar vehículos del usuario
const getVehiculos = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT 
        v.id, v.alias, v.marca_manual, v.modelo_manual, v.anio_manual,
        v.rendimiento_km_l, v.es_principal, v.creado_en,
        tc.nombre AS combustible,
        vm.marca AS marca_oficial, vm.modelo AS modelo_oficial, vm.anio,
        vm.official_efficiency AS rendimiento_oficial
      FROM vehiculos v
      JOIN tipos_combustible tc ON tc.id = v.tipo_combustible_id
      LEFT JOIN modelos_vehiculo vm ON vm.id = v.modelo_id
      WHERE v.usuario_id = ?
      ORDER BY v.es_principal DESC, v.creado_en DESC
    `, [req.usuarioId])

    res.json(rows)
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener vehículos' })
  }
}

// Eliminar vehículo
const eliminarVehiculo = async (req, res) => {
  try {
    const [result] = await pool.query(
      'DELETE FROM vehiculos WHERE id = ? AND usuario_id = ?',
      [req.params.id, req.usuarioId]
    )

    if (!result.affectedRows) {
      return res.status(404).json({ error: 'Vehículo no encontrado' })
    }

    res.json({ mensaje: 'Vehículo eliminado' })
  } catch (err) {
    res.status(500).json({ error: 'Error al eliminar vehículo' })
  }
}

// Calcular costo por km en una estación
const calcularCosto = async (req, res) => {
  const { vehiculo_id, estacion_id, distancia_km } = req.query

  if (!vehiculo_id || !estacion_id) {
    return res.status(400).json({ error: 'vehiculo_id y estacion_id son requeridos' })
  }

  try {
    // Obtener vehículo
    const [vehiculo] = await pool.query(
      'SELECT * FROM vehiculos WHERE id = ? AND usuario_id = ?',
      [vehiculo_id, req.usuarioId]
    )
    if (!vehiculo.length) {
      return res.status(404).json({ error: 'Vehículo no encontrado' })
    }

    // Obtener precio actual del combustible del vehículo en esa estación
    const [precio] = await pool.query(`
      SELECT hp.precio, tc.nombre AS combustible
      FROM historial_precios hp
      JOIN tipos_combustible tc ON tc.id = hp.tipo_combustible_id
      WHERE hp.estacion_id = ? AND hp.tipo_combustible_id = ?
      ORDER BY hp.fecha_registro DESC LIMIT 1
    `, [estacion_id, vehiculo[0].tipo_combustible_id])

    if (!precio.length) {
      return res.status(404).json({ error: 'No hay precio disponible para este combustible en esta estación' })
    }

    const precioLitro   = parseFloat(precio[0].precio)
    const rendimiento   = vehiculo[0].rendimiento_km_l
    const costoPorKm    = precioLitro / rendimiento
    const distancia     = parseFloat(distancia_km) || 1

    res.json({
      vehiculo        : vehiculo[0].alias || vehiculo[0].modelo_manual,
      combustible     : precio[0].combustible,
      precio_litro    : precioLitro,
      rendimiento_km_l: rendimiento,
      costo_por_km    : Math.round(costoPorKm),
      distancia_km    : distancia,
      costo_total     : Math.round(costoPorKm * distancia)
    })

  } catch (err) {
    console.error(err)
    res.status(500).json({ error: 'Error al calcular costo' })
  }
}

module.exports = { crearVehiculo, getVehiculos, eliminarVehiculo, calcularCosto }