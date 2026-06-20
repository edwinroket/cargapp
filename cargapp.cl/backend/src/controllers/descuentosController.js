const pool = require('../models/db')

const shouldFilter = value => {
  if (!value) return false
  const normalized = value.toString().trim().toLowerCase()
  return !['todas', 'todos', 'todos los días', 'todos los dias'].includes(normalized)
}

// FUNCIÓN CLASIFICADORA EN BASE A TU INTERFAZ WEB DE REFERENCIA
const clasificarConvenio = (convenio, origen) => {
  // Combinamos todo y removemos acentos/tildes de forma manual para evitar fallos de coincidencia
  let name = `${convenio || ''} ${origen || ''}`.toLowerCase();
  name = name.normalize("NFD").replace(/[\u0300-\u036f]/g, ""); // Convierte "ejército" en "ejercito"

  // 1. Tarjetas Bancarias
  if (name.includes('scotiabank') || name.includes('itau') || name.includes('consorcio') || name.includes('visa') || name.includes('mastercard') || name.includes('bice') || name.includes('chile') || name.includes('santander') || name.includes('bci') || name.includes('internacional') || name.includes('security')) {
    return 'Tarjetas Bancarias';
  }

  // 2. Tarjetas Retail
  if (name.includes('ripley') || name.includes('coopeuch') || name.includes('sbpay') || name.includes('abc') || name.includes('cencosud') || name.includes('jumbo') || name.includes('lider')) {
    return 'Tarjetas Retail';
  }

  // 3. App / Digital
  if (name.includes('tenpo') || name.includes('mach') || name.includes('copec pay') || name.includes('mercado pago') || name.includes('spin')) {
    return 'App / Digital';
  }

  // 4. RUT / Municipal / Instituciones (¡Aquí entran todas las tuyas!)
  if (name.includes('municipal') || name.includes('amuch') || name.includes('achm') || name.includes('carabineros') || name.includes('ejercito') || name.includes('fach') || name.includes('armada') || name.includes('jenabien')) {
    return 'RUT / Municipal';
  }

  // 5. App transporte / Conductores
  if (name.includes('uber') || name.includes('cabify') || name.includes('taxistas') || name.includes('transportistas')) {
    return 'App transporte';
  }

  // 6. Cajas de Compensación (Si llegasen a entrar en la sync futura)
  if (name.includes('caja') || name.includes('andes') || name.includes('septiembre') || name.includes('araucana')) {
    return 'Cajas de Compensación';
  }
  
  return 'Otro';
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

    // ⚡ INYECTAMOS LA CATEGORÍA DINÁMICAMENTE ANTES DE ENVIAR
    const rowsConCategoria = rows.map(row => ({
      ...row,
      categoria_visual: clasificarConvenio(row.convenio, row.origen)
    }))

    res.json(rowsConCategoria)
  } catch (err) {
    console.error('Error get descuentos:', err.message)
    res.status(500).json({ error: 'Error al obtener descuentos' })
  }
}

module.exports = { getDescuentos }