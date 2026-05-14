const pool = require('../models/db');

// 1. Para el MAPA (Agrupado por JSON para evitar duplicados)
const getMapa = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT e.*, 
      JSON_ARRAYAGG(
        JSON_OBJECT(
          'combustible', tc.nombre,
          'precio', pa.precio,
          'fecha_actualizacion', pa.fecha_actualizacion
        )
      ) AS combustibles
      FROM estaciones e
      INNER JOIN precios_actuales pa ON e.id = pa.estacion_id
      JOIN tipos_combustible tc ON tc.id = pa.tipo_combustible_id
      WHERE e.activa = 1
      GROUP BY e.id
    `);
    
    res.json({ total: rows.length, estaciones: rows }); 
  } catch (err) {
    console.error('Error en getMapa:', err);
    res.status(500).json({ error: 'Error al obtener estaciones' });
  }
};

// 2. Para BUSCADOR (Filtrado por GPS + Agrupación JSON)
const getCercanas = async (req, res) => {
  const { lat, lng, radio = 5 } = req.query;
  if (!lat || !lng) return res.status(400).json({ error: 'Se requiere lat y lng' });

  try {
    const [rows] = await pool.query(`
      SELECT e.*, 
      (6371 * ACOS(LEAST(1, COS(RADIANS(?)) * COS(RADIANS(latitud)) * COS(RADIANS(longitud) - RADIANS(?)) + SIN(RADIANS(?)) * SIN(RADIANS(latitud))))) AS distancia,
      JSON_ARRAYAGG(
        JSON_OBJECT(
          'combustible', tc.nombre,
          'precio', pa.precio,
          'fecha_actualizacion', pa.fecha_actualizacion
        )
      ) AS combustibles
      FROM estaciones e
      INNER JOIN precios_actuales pa ON e.id = pa.estacion_id
      JOIN tipos_combustible tc ON tc.id = pa.tipo_combustible_id
      WHERE e.activa = 1
      GROUP BY e.id
      HAVING distancia <= ?
      ORDER BY distancia ASC
      LIMIT 15
    `, [parseFloat(lat), parseFloat(lng), parseFloat(lat), parseFloat(radio)]);

    res.json({ total: rows.length, estaciones: rows });
  } catch (err) {
    console.error('Error en getCercanas:', err);
    res.status(500).json({ error: 'Error al buscar cercanas' });
  }
};

// 3. Detalle de Estación
const getDetalle = async (req, res) => {
    const { id } = req.params;
    try {
        // Obtener datos básicos de la estación
        const [estacionRows] = await pool.query('SELECT * FROM estaciones WHERE id = ?', [id]);
        
        if (estacionRows.length === 0) {
            return res.status(404).json({ error: 'Estación no encontrada' });
        }

        const estacion = estacionRows[0];

        // Obtener precios actuales
        const [precios] = await pool.query(`
            SELECT tc.nombre AS combustible, pa.precio, pa.fecha_actualizacion, pa.fuente
            FROM precios_actuales pa
            JOIN tipos_combustible tc ON tc.id = pa.tipo_combustible_id
            WHERE pa.estacion_id = ?
            ORDER BY pa.precio ASC
        `, [id]);

        // Obtener descuentos (Corregido: Sin filtrar por columna 'comuna' inexistente)
        // Traemos los descuentos activos que coincidan con la marca de la estación
        const [descuentos] = await pool.query(`
            SELECT * FROM descuentos 
            WHERE activo = 1 
            AND (origen LIKE ? OR convenio LIKE ?)
        `, [`%${estacion.marca}%`, `%${estacion.marca}%`]);

        res.json({
            estacion: estacion,
            precios_actuales: precios,
            descuentos: descuentos
        });

    } catch (err) {
        console.error('Error en getDetalle:', err.message);
        res.status(500).json({ error: 'Error al obtener detalle de la estación' });
    }
};

// 4. Listar tipos de combustible
const getTiposCombustible = async (req, res) => {
  try {
    const [rows] = await pool.query(`SELECT * FROM tipos_combustible WHERE activo = 1`);
    res.json(rows);
  } catch (err) {
    console.error('Error en getTiposCombustible:', err);
    res.status(500).json({ error: 'Error al obtener tipos de combustible' });
  }
};

module.exports = { 
    getMapa, 
    getCercanas, 
    getDetalle, 
    getTiposCombustible 
};