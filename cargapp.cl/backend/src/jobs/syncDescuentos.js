const pool  = require('../models/db')
const axios = require('axios')

const syncDescuentos = async () => {
  console.log('Sincronizando descuentos desde bencinabarata.cl...')
  try {
    const hoy = new Date().toISOString().split('T')[0]

    const resp = await axios.get('https://exmbjldynzzldhvrddoo.supabase.co/rest/v1/descuentos', {
      params: {
        select        : 'dia,convenio,descuento_por_litro,tipo,condicion,tope_mensual,notas,origen,fuente_url,descuento_num,vigencia_hasta,is_active',
        is_active     : 'eq.true',
        vigencia_desde: `lte.${hoy}`,
        vigencia_hasta: `gte.${hoy}`
      },
      headers: {
        'apikey'       : 'sb_publishable_KFufDUA05Fcgi3sLBGPAng_OESoLpd5',
        'Authorization': 'Bearer sb_publishable_KFufDUA05Fcgi3sLBGPAng_OESoLpd5',
        'Accept'       : 'application/json'
      }
    })

    const descuentos = resp.data
    console.log(`Descuentos recibidos: ${descuentos.length}`)

    // Limpiar descuentos anteriores y reinsertar
    await pool.query('DELETE FROM descuentos')

    for (const d of descuentos) {
      await pool.query(`
        INSERT INTO descuentos
          (origen, convenio, tipo, dia, descuento_num, descuento_texto,
           condicion, tope_mensual, notas, fuente_url, vigencia_hasta, activo, ultima_sync)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, NOW())
      `, [
        d.origen        || null,
        d.convenio      || null,
        d.tipo          || null,
        d.dia           || null,
        d.descuento_num || null,
        d.descuento_por_litro || null,
        d.condicion     || null,
        d.tope_mensual  || null,
        d.notas         || null,
        d.fuente_url    || null,
        d.vigencia_hasta || null
      ])
    }

    console.log(`Sync descuentos completada: ${descuentos.length} guardados`)

  } catch (err) {
    console.error('Error sync descuentos:', err.message)
  }
}

module.exports = { syncDescuentos }