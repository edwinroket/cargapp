const pool  = require('../models/db')
const axios = require('axios')

const syncEstaciones = async () => {
  console.log('Iniciando sincronización con bencinaenlinea.cl...')
  try {
    const resp = await axios.get('https://api.bencinaenlinea.cl/api/busqueda_estacion_filtro', {
      headers: {
        'Accept'    : 'application/json',
        'User-Agent': 'Mozilla/5.0'
      },
      decompress: true
    })

    const estaciones = resp.data.data
    console.log(`Total estaciones recibidas: ${estaciones.length}`)

    let insertadas = 0, actualizadas = 0, precios = 0

    for (const e of estaciones) {
      const [existe] = await pool.query(
        'SELECT id FROM estaciones WHERE cne_id = ?', [e.id]
      )

      let estacionId

      if (existe.length) {
        await pool.query(`
          UPDATE estaciones SET
            nombre = ?, marca = ?, direccion = ?,
            latitud = ?, longitud = ?,
            region = ?, comuna = ?,
            ultima_sync_cne = NOW()
          WHERE cne_id = ?
        `, [
          e.direccion, e.marca, e.direccion,
          parseFloat(e.latitud), parseFloat(e.longitud),
          e.region, e.comuna,
          e.id
        ])
        estacionId = existe[0].id
        actualizadas++
      } else {
        const [ins] = await pool.query(`
          INSERT INTO estaciones
            (cne_id, nombre, marca, direccion, latitud, longitud, region, comuna, ultima_sync_cne)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())
        `, [
          e.id, e.direccion, e.marca, e.direccion,
          parseFloat(e.latitud), parseFloat(e.longitud),
          e.region, e.comuna
        ])
        estacionId = ins.insertId
        insertadas++
      }

      for (const c of e.combustibles) {
        const [tipo] = await pool.query(
            `SELECT id FROM tipos_combustible WHERE nombre LIKE ?`,
            [`%${c.nombre_largo}%`]
        )
        if (!tipo.length) continue

        const precio = parseFloat(c.precio)
        if (!precio) continue

        // Solo insertar si el precio es diferente al último registrado
        const [ultimo] = await pool.query(`
            SELECT precio FROM historial_precios
            WHERE estacion_id = ? AND tipo_combustible_id = ?
            ORDER BY fecha_registro DESC LIMIT 1
        `, [estacionId, tipo[0].id])

        if (ultimo.length && parseFloat(ultimo[0].precio) === precio) continue

        await pool.query(`
            INSERT INTO historial_precios (estacion_id, tipo_combustible_id, precio, fecha_registro, fuente)
            VALUES (?, ?, ?, NOW(), 'cne')
        `, [estacionId, tipo[0].id, precio])
        precios++
        }
    }

    console.log(`Sync completada: ${insertadas} nuevas, ${actualizadas} actualizadas, ${precios} precios guardados`)

  } catch (err) {
    console.error('Error en sync:', err.message)
  }
}

module.exports = { syncEstaciones }