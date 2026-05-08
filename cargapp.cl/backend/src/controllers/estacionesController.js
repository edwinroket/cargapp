const pool = require('../models/db')

// 1. Para el MAPA (Trae todas las estaciones activas)
const getMapa = async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM estaciones WHERE activa = 1');
    // Devolvemos el formato que espera tu Flutter
    res.json({ total: rows.length, estaciones: rows }); 
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener estaciones' });
  }
}

// 2. Para REPORTES y BUSCADOR (Filtrado por GPS)
const getCercanas = async (req, res) => {
  const { lat, lng, radio = 5 } = req.query;
  if (!lat || !lng) return res.status(400).json({ error: 'Se requiere lat y lng' });

  try {
    const [rows] = await pool.query(`
      SELECT id, nombre, direccion, marca, latitud, longitud,
      (6371 * ACOS(LEAST(1, COS(RADIANS(?)) * COS(RADIANS(latitud)) * COS(RADIANS(longitud) - RADIANS(?)) + SIN(RADIANS(?)) * SIN(RADIANS(latitud))))) AS distancia
      FROM estaciones
      WHERE activa = 1
      HAVING distancia <= ?
      ORDER BY distancia ASC
      LIMIT 15
    `, [parseFloat(lat), parseFloat(lng), parseFloat(lat), parseFloat(radio)]);

    res.json({ total: rows.length, estaciones: rows });
  } catch (err) {
    res.status(500).json({ error: 'Error' });
  }
};

const getDetalle = async (req, res) => {
  const { id } = req.params;
  try {
    const [estacion] = await pool.query(`SELECT * FROM estaciones WHERE id = ?`, [id]);
    
    const [precios] = await pool.query(`
      SELECT tc.nombre AS combustible, hp.precio, hp.fecha_registro, hp.fuente
      FROM historial_precios hp
      JOIN tipos_combustible tc ON tc.id = hp.tipo_combustible_id
      WHERE hp.estacion_id = ?
      ORDER BY hp.fecha_registro DESC LIMIT 15
    `, [id]);

    res.json({ 
      estacion: estacion[0], 
      precios_actuales: precios, 
      historial: precios // Enviamos los precios como historial para que se llene la lista
    });
  } catch (err) {
    res.status(500).json({ error: 'Error' });
  }
};

const getTiposCombustible = async (req, res) => {
  try {
    const [rows] = await pool.query(`SELECT * FROM tipos_combustible WHERE activo = 1`)
    res.json(rows)
  } catch (err) {
    res.status(500).json({ error: 'Error combustible' })
  }
}

module.exports = { getMapa, getCercanas, getDetalle, getTiposCombustible }