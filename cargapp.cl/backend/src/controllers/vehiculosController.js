const pool = require('../models/db');

// 1. Agregar vehículo (Oficial o Manual)
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
    } = req.body;

    if (!rendimiento_km_l || !tipo_combustible_id) {
        return res.status(400).json({ error: 'Rendimiento y tipo de combustible son requeridos' });
    }

    try {
        if (es_principal) {
            await pool.query(
                'UPDATE vehiculos SET es_principal = 0 WHERE usuario_id = ?',
                [req.usuarioId]
            );
        }

        const [result] = await pool.query(`
            INSERT INTO vehiculos 
                (usuario_id, modelo_id, alias, marca_manual, modelo_manual, anio_manual, 
                 rendimiento_km_l, tipo_combustible_id, es_principal, activo) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
        `, [
            req.usuarioId,
            modelo_id || null,
            alias || null,
            marca_manual || null,
            modelo_manual || null,
            anio_manual || null,
            rendimiento_km_l,
            tipo_combustible_id,
            es_principal ? 1 : 0
        ]);

        res.status(201).json({ mensaje: 'Vehículo agregado exitosamente', id: result.insertId });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Error al crear vehículo' });
    }
};

// 2. Listar vehículos ACTIVOS del usuario
const getVehiculos = async (req, res) => {
    try {
        const [rows] = await pool.query(`
            SELECT 
                v.id, v.alias, v.marca_manual, v.modelo_manual, v.anio_manual,
                v.rendimiento_km_l, v.es_principal, v.creado_en,
                tc.nombre AS combustible,
                vm.marca AS marca_oficial, 
                vm.modelo AS modelo_oficial, 
                vm.detalle AS detalle_oficial,
                vm.rendimiento_mixto AS rendimiento_oficial
            FROM vehiculos v
            JOIN tipos_combustible tc ON tc.id = v.tipo_combustible_id
            LEFT JOIN modelos_vehiculo vm ON vm.id = v.modelo_id
            WHERE v.usuario_id = ? AND v.activo = 1
            ORDER BY v.es_principal DESC, v.creado_en DESC
        `, [req.usuarioId]);

        const formatted = rows.map((v) => ({
            id: v.id,
            alias: v.alias,
            marca: v.marca_oficial || v.marca_manual,
            modelo: v.modelo_oficial || v.modelo_manual,
            detalle: v.detalle_oficial || '',
            anio: v.anio_manual || '',
            rendimiento_km_l: v.rendimiento_km_l,
            rendimiento_oficial: v.rendimiento_oficial,
            tipo_combustible: v.combustible,
            es_principal: Boolean(v.es_principal),
            creado_en: v.creado_en,
            nombre_mostrado: v.alias || `${v.marca_oficial || v.marca_manual} ${v.modelo_oficial || v.modelo_manual}`
        }));

        res.json(formatted);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Error al obtener vehículos' });
    }
};

// 3. Obtener un vehículo específico (solo si está activo)
const getVehiculo = async (req, res) => {
    try {
        const [rows] = await pool.query(`
            SELECT 
                v.*, tc.nombre AS combustible,
                vm.marca AS marca_oficial, vm.modelo AS modelo_oficial, vm.detalle AS detalle_oficial
            FROM vehiculos v
            JOIN tipos_combustible tc ON tc.id = v.tipo_combustible_id
            LEFT JOIN modelos_vehiculo vm ON vm.id = v.modelo_id
            WHERE v.id = ? AND v.usuario_id = ? AND v.activo = 1
        `, [req.params.id, req.usuarioId]);

        if (!rows.length) {
            return res.status(404).json({ error: 'Vehículo no encontrado' });
        }

        res.json(rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Error al obtener el vehículo' });
    }
};

// 4. Borrado Lógico (Soft Delete)
const eliminarVehiculo = async (req, res) => {
    try {
        const [result] = await pool.query(
            'UPDATE vehiculos SET activo = 0, es_principal = 0 WHERE id = ? AND usuario_id = ?',
            [req.params.id, req.usuarioId]
        );

        if (!result.affectedRows) {
            return res.status(404).json({ error: 'Vehículo no encontrado' });
        }
        res.json({ mensaje: 'Vehículo removido del garage' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Error al desactivar vehículo' });
    }
};

// 5. Calcular costo (Solo vehículos activos)
const calcularCosto = async (req, res) => {
    const { vehiculo_id, estacion_id, distancia_km } = req.query;

    if (!vehiculo_id || !estacion_id) {
        return res.status(400).json({ error: 'vehiculo_id y estacion_id son requeridos' });
    }

    try {
        const [vehiculo] = await pool.query(
            'SELECT * FROM vehiculos WHERE id = ? AND usuario_id = ? AND activo = 1',
            [vehiculo_id, req.usuarioId]
        );
        
        if (!vehiculo.length) {
            return res.status(404).json({ error: 'Vehículo no encontrado' });
        }

        const [precio] = await pool.query(`
            SELECT hp.precio, tc.nombre AS combustible
            FROM historial_precios hp
            JOIN tipos_combustible tc ON tc.id = hp.tipo_combustible_id
            WHERE hp.estacion_id = ? AND hp.tipo_combustible_id = ?
            ORDER BY hp.fecha_registro DESC LIMIT 1
        `, [estacion_id, vehiculo[0].tipo_combustible_id]);

        if (!precio.length) {
            return res.status(404).json({ error: 'Precio no disponible para este combustible en esta estación' });
        }

        const precioLitro = parseFloat(precio[0].precio);
        const rendimiento = vehiculo[0].rendimiento_km_l;
        const costoPorKm = precioLitro / rendimiento;
        const distancia = parseFloat(distancia_km) || 1;

        res.json({
            vehiculo: vehiculo[0].alias || vehiculo[0].modelo_manual || 'Mi Vehículo',
            combustible: precio[0].combustible,
            precio_litro: precioLitro,
            rendimiento_km_l: rendimiento,
            costo_por_km: Math.round(costoPorKm),
            distancia_km: distancia,
            costo_total: Math.round(costoPorKm * distancia)
        });

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Error al calcular costo' });
    }
};

// (Las funciones 6, 7 y 8 se mantienen igual que tu código previo)
const getModelosVehiculo = async (req, res) => {
    try {
        const { marca, buscar } = req.query;
        let sql = 'SELECT id, id_vehiculo_ministerio, marca, modelo, detalle, rendimiento_mixto, combustible_label FROM modelos_vehiculo WHERE 1=1';
        const params = [];
        if (marca) { sql += ' AND marca = ?'; params.push(marca.toUpperCase()); }
        if (buscar) { sql += ' AND (modelo LIKE ? OR detalle LIKE ?)'; params.push(`%${buscar}%`, `%${buscar}%`); }
        sql += ' ORDER BY marca, modelo, detalle LIMIT 100';
        const [rows] = await pool.query(sql, params);
        res.json(rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Error al listar catálogo de modelos' });
    }
};

const getModeloVehiculo = async (req, res) => {
    try {
        const [rows] = await pool.query('SELECT * FROM modelos_vehiculo WHERE id = ?', [req.params.id]);
        if (!rows.length) return res.status(404).json({ error: 'Modelo no encontrado' });
        res.json(rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Error al obtener modelo' });
    }
};

const crearModeloVehiculo = async (req, res) => {
    const { marca, modelo, detalle, rendimiento_mixto, tipo_combustible_id } = req.body;
    if (!marca || !modelo || !rendimiento_mixto) return res.status(400).json({ error: 'Faltan campos' });
    try {
        const [result] = await pool.query(
            'INSERT INTO modelos_vehiculo (marca, modelo, detalle, rendimiento_mixto, tipo_combustible_id) VALUES (?, ?, ?, ?, ?)',
            [marca.toUpperCase(), modelo.toUpperCase(), detalle, rendimiento_mixto, tipo_combustible_id]
        );
        res.status(201).json({ mensaje: 'Modelo agregado', id: result.insertId });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Error al crear modelo' });
    }
};

module.exports = { 
    crearVehiculo, getVehiculos, getVehiculo, eliminarVehiculo, 
    calcularCosto, getModelosVehiculo, getModeloVehiculo, crearModeloVehiculo 
};