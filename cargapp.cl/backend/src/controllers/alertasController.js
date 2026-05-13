const pool = require('../models/db');

// 1. Listar alertas (Solo las NO eliminadas lógicamente)
const getAlertas = async (req, res) => {
    try {
        const [rows] = await pool.query(`
            SELECT a.id, a.precio_umbral, a.radio_km, a.activa, a.estacion_id,
                   a.latitud_usuario, a.longitud_usuario,
                   a.ultima_notificacion, a.creado_en,
                   tc.nombre AS combustible,
                   e.nombre AS estacion, e.direccion AS estacion_direccion
            FROM alertas a
            JOIN tipos_combustible tc ON tc.id = a.tipo_combustible_id
            LEFT JOIN estaciones e ON e.id = a.estacion_id
            WHERE a.usuario_id = ? AND a.eliminada = 0
            ORDER BY a.creado_en DESC
        `, [req.usuarioId]);
        res.json(rows);
    } catch (err) {
        console.error('Error al obtener alertas:', err);
        res.status(500).json({ error: 'Error al obtener alertas' });
    }
};

// 2. Eliminar Alerta (Soft Delete)
const eliminarAlerta = async (req, res) => {
    const { id } = req.params;
    try {
        const [result] = await pool.query(
            'UPDATE alertas SET eliminada = 1, activa = 0 WHERE id = ? AND usuario_id = ?',
            [id, req.usuarioId]
        );
        if (result.affectedRows === 0) return res.status(404).json({ error: 'Alerta no encontrada' });
        res.json({ mensaje: 'Alerta eliminada correctamente' });
    } catch (err) {
        res.status(500).json({ error: 'Error al eliminar alerta' });
    }
};

// 3. Toggle Alerta (Switch ON/OFF)
const toggleAlerta = async (req, res) => {
    const { id } = req.params;
    const { activa } = req.body; 
    try {
        await pool.query(
            'UPDATE alertas SET activa = ? WHERE id = ? AND usuario_id = ?',
            [activa, id, req.usuarioId]
        );
        res.json({ mensaje: `Alerta ${activa ? 'activada' : 'desactivada'}` });
    } catch (err) {
        res.status(500).json({ error: 'Error al actualizar estado' });
    }
};

// 4. Crear alerta
const crearAlerta = async (req, res) => {
    const { tipo_combustible_id, precio_umbral, radio_km, latitud_usuario, longitud_usuario, estacion_id } = req.body;
    try {
        const [result] = await pool.query(`
            INSERT INTO alertas (usuario_id, tipo_combustible_id, precio_umbral, radio_km, latitud_usuario, longitud_usuario, estacion_id, activa, eliminada)
            VALUES (?, ?, ?, ?, ?, ?, ?, 1, 0)
        `, [req.usuarioId, tipo_combustible_id, precio_umbral, radio_km || 5, latitud_usuario, longitud_usuario, estacion_id]);
        res.status(201).json({ mensaje: 'Alerta creada', id: result.insertId });
    } catch (err) {
        res.status(500).json({ error: 'Error al crear alerta' });
    }
};

// 5. Función para el CRON JOB mejorada (Verificación con ubicación)
const verificarAlertas = async () => {
    console.log('--- [SISTEMA] Verificando alertas activas ---');
    try {
        const [alertas] = await pool.query(`
            SELECT a.*, tc.nombre AS combustible
            FROM alertas a
            JOIN tipos_combustible tc ON tc.id = a.tipo_combustible_id
            WHERE a.activa = 1 AND a.eliminada = 0
        `);

        for (const alerta of alertas) {
            // Buscamos si hay precios bajos en la zona o estación específica
            // Se une con estaciones para obtener nombre y dirección para la notificación
            const [resultado] = await pool.query(`
                SELECT hp.precio, e.nombre as estacion_nombre, e.direccion, e.id as estacion_id
                FROM historial_precios hp
                JOIN estaciones e ON e.id = hp.estacion_id
                WHERE hp.tipo_combustible_id = ? 
                  AND hp.precio <= ?
                  AND ( ? IS NULL OR e.id = ? )
                ORDER BY hp.fecha_registro DESC LIMIT 1
            `, [alerta.tipo_combustible_id, alerta.precio_umbral, alerta.estacion_id, alerta.estacion_id]);

            if (resultado.length > 0) {
                const res = resultado[0];
                console.log(`¡MATCH! Usuario ${alerta.usuario_id}: ${res.estacion_nombre} ($${res.precio})`);
                
                // Actualizar última notificación para no repetir avisos inmediatamente
                await pool.query('UPDATE alertas SET ultima_notificacion = NOW() WHERE id = ?', [alerta.id]);
                
                // AQUÍ: Integración con FCM (Firebase Cloud Messaging) en el futuro
            }
        }
    } catch (err) {
        console.error('Error en verificarAlertas:', err.message);
    }
};

module.exports = { crearAlerta, getAlertas, toggleAlerta, verificarAlertas, eliminarAlerta };