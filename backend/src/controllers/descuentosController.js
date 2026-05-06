const pool = require('../models/db')

const shouldFilter = value => {
  if (!value) return false
  const normalized = value.toString().trim().toLowerCase()
  return !['todas', 'todos', 'todos los días', 'todos los dias'].includes(normalized)
}

const getDescuentos = async (req, res) => {
  try {
    const { dia, origen, tipo } = req.query
    let sql = `
      SELECT
        id,
        origen,
        convenio,
        tipo,
        dia,
        descuento_num,
        descuento_texto,
        condicion,
        tope_mensual,
        notas,
        fuente_url,
        vigencia_hasta
      FROM descuentos
      WHERE activo = 1
    `
    const params = []

    if (shouldFilter(dia)) {
      sql += ' AND dia = ?'
      params.push(dia)
    }
    if (shouldFilter(origen)) {
      sql += ' AND origen = ?'
      params.push(origen)
    }
    if (shouldFilter(tipo)) {
      sql += ' AND tipo = ?'
      params.push(tipo)
    }

    sql += ' ORDER BY descuento_num DESC, convenio ASC LIMIT 250'

    const [rows] = await pool.query(sql, params)
    res.json(rows)
  } catch (err) {
    console.error('Error get descuentos:', err.message)
    res.status(500).json({ error: 'Error al obtener descuentos' })
  }
  
}

module.exports = { getDescuentos }
