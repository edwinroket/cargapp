const pool = require('../models/db');

const getPreciosGas = async (req, res) => {
    // Recibimos comunaId (opcional) para filtrar
    const { comunaId } = req.query;

    try {
        let query = `
            SELECT 
                m.nombre as marca, 
                m.logo_url, 
                pv.nombre as local, 
                pv.direccion, 
                pv.telefono, 
                pv.latitud, 
                pv.longitud,
                t.nombre as formato, 
                p.precio, 
                p.fecha_actualizacion
            FROM gas_precios p
            JOIN gas_puntos_venta pv ON p.punto_venta_id = pv.id
            JOIN gas_marcas m ON pv.marca_id = m.id
            JOIN gas_tipos t ON p.tipo_gas_id = t.id
        `;
        
        const params = [];
        if (comunaId) {
            query += " WHERE pv.comuna_id = ?";
            params.push(comunaId);
        }

        query += " ORDER BY p.precio ASC";

        const [rows] = await pool.query(query, params);
        res.json(rows);

    } catch (err) {
        console.error(' [GAS-ERROR] en getPreciosGas:', err);
        res.status(500).json({ error: 'Error al obtener datos de gas' });
    }
};

module.exports = { getPreciosGas };