const pool = require('../models/db');

const getPreciosGas = async (req, res) => {
    const { lat, lng, radio = 20, comunaId } = req.query;

    try {
        let query = `
            SELECT 
                pv.id,
                m.nombre as marca, 
                m.logo_url, 
                pv.nombre as local, 
                pv.direccion, 
                pv.telefono, 
                pv.latitud, 
                pv.longitud,
                pv.comuna_id,
        `;

        const params = [];

        if (lat && lng) {
            query += ` (6371 * ACOS(LEAST(1, COS(RADIANS(?)) * COS(RADIANS(pv.latitud)) * COS(RADIANS(pv.longitud) - RADIANS(?)) + SIN(RADIANS(?)) * SIN(RADIANS(pv.latitud))))) AS distancia,`;
            params.push(parseFloat(lat), parseFloat(lng), parseFloat(lat));
        } else {
            query += ` NULL AS distancia,`;
        }

        // CLAVE: Aseguramos que las llaves del JSON_OBJECT estén estrictamente en minúsculas
        query += `
                JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'formato', CAST(t.nombre AS CHAR),
                        'precio', p.precio
                    )
                ) AS formatos
            FROM gas_puntos_venta pv
            JOIN gas_precios p ON p.punto_venta_id = pv.id
            JOIN gas_marcas m ON pv.marca_id = m.id
            JOIN gas_tipos t ON p.tipo_gas_id = t.id
        `;

        let condiciones = [];
        if (comunaId) {
            condiciones.push("pv.comuna_id = ?");
            params.push(comunaId);
        }

        if (condiciones.length > 0) {
            query += " WHERE " + condiciones.join(" AND ");
        }

        query += " GROUP BY pv.id";

        if (lat && lng) {
            query += " HAVING distancia <= ? OR pv.latitud = 0";
            params.push(parseFloat(radio));
            query += " ORDER BY CASE WHEN pv.latitud = 0 THEN 1 ELSE 0 END, distancia ASC";
        } else {
            query += " ORDER BY pv.nombre ASC";
        }

        const [rows] = await pool.query(query, params);

        // Forzar el parseo del string JSON que entrega MariaDB a un array real de JS
        const respuestaParseada = rows.map(row => {
            if (row.formatos) {
                if (typeof row.formatos === 'string') {
                    try {
                        row.formatos = JSON.parse(row.formatos);
                    } catch (e) {
                        console.error("Error parseando formatos string:", e);
                        row.formatos = [];
                    }
                }
            } else {
                row.formatos = [];
            }
            return row;
        });

        res.json(respuestaParseada);

    } catch (err) {
        console.error(' [GAS-ERROR] en getPreciosGas:', err);
        res.status(500).json({ error: 'Error al obtener datos de gas de forma cercana' });
    }
};

module.exports = { getPreciosGas };