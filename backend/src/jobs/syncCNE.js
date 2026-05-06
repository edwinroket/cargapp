const pool = require('../models/db');
const axios = require('axios');
require('dotenv').config();

const getFreshToken = async () => {
    try {
        const params = new URLSearchParams();
        params.append("email", process.env.CNE_EMAIL);
        params.append("password", process.env.CNE_PASSWORD);

        const resp = await axios.post(`${process.env.CNE_API_URL}/api/login`, params, {
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
        });

        const token = resp.data?.token;
        if (token) console.log(' [CNE] Token obtenido exitosamente.');
        return token;
    } catch (err) {
        console.error(' [CNE] Error en Login:', err.message);
        return null;
    }
};

const syncEstaciones = async () => {
    console.log(' [CNE] Iniciando sincronización API v4...');
    
    const token = await getFreshToken();
    if (!token) return;

    try {
        const respEstaciones = await axios.get(`${process.env.CNE_API_URL}/api/v4/estaciones`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });

        const estaciones = respEstaciones.data?.data || respEstaciones.data;
        if (!estaciones || !Array.isArray(estaciones)) {
            console.error(' [CNE] No se recibieron estaciones válidas.');
            return;
        }

        const totalCNE = estaciones.length;
        console.log(` [CNE] Procesando ${totalCNE} estaciones detectadas...`);

        let insertadas = 0, actualizadas = 0, preciosCont = 0, procesadas = 0;

        for (const e of estaciones) {
            procesadas++;
            const cne_id = String(e.codigo || e.id || '');
            if (!cne_id) continue;

            const [existe] = await pool.query(
                'SELECT id FROM estaciones WHERE cne_id = ?', [cne_id]
            );

            let estacionId;
            const marcaNombre = e.distribuidor?.nombre || e.distribuidor?.marca || 'S/M';
            
            const servicios = e.servicios || {};
            const datos = [
                e.razon_social || e.nombre_fantasia || 'Estación sin nombre',
                marcaNombre,
                e.ubicacion?.direccion || 'Dirección no informada',
                parseFloat(e.ubicacion?.latitud || 0),
                parseFloat(e.ubicacion?.longitud || 0),
                e.ubicacion?.nombre_region || 'S/R',
                e.ubicacion?.nombre_comuna || 'S/C',
                e.horario_atencion || 'No disponible',
                servicios['Baño público'] ? 1 : 0,
                servicios['Tienda de conveniencia'] ? 1 : 0,
                servicios['Lubricentro'] ? 1 : 0,
                servicios['Cajero automático'] ? 1 : 0,
                servicios['Compresor de aire para neumáticos'] ? 1 : 0,
                servicios['Lavado de autos'] ? 1 : 0,
                cne_id
            ];

            if (existe.length > 0) {
                await pool.query(`
                    UPDATE estaciones SET
                        nombre = ?, marca = ?, direccion = ?,
                        latitud = ?, longitud = ?, region = ?,
                        comuna = ?, horario = ?, 
                        tiene_bano = ?, tiene_tienda = ?, tiene_lubricentro = ?,
                        tiene_cajero = ?, tiene_aire = ?, tiene_lavado = ?,
                        ultima_sync_cne = NOW()
                    WHERE cne_id = ?
                `, datos);
                estacionId = existe[0].id;
                actualizadas++;
            } else {
                const [ins] = await pool.query(`
                    INSERT INTO estaciones
                        (nombre, marca, direccion, latitud, longitud, region, comuna, horario, 
                         tiene_bano, tiene_tienda, tiene_lubricentro, tiene_cajero, tiene_aire, tiene_lavado,
                         cne_id, ultima_sync_cne)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
                `, datos);
                estacionId = ins.insertId;
                insertadas++;
            }

            if (e.precios) {
                for (const [codCombustible, info] of Object.entries(e.precios)) {
                    const valorPrecio = typeof info === 'object' ? (info.precio || (Array.isArray(info) ? info[0]?.precio : null)) : info;
                    const precioActual = parseFloat(valorPrecio || 0);
                    
                    if (!precioActual || precioActual <= 0) continue;

                    const [tipoInterno] = await pool.query(
                        'SELECT id FROM tipos_combustible WHERE nombre LIKE ? OR nombre LIKE ?',
                        [`%${codCombustible}%`, codCombustible === 'DI' ? '%Diesel%' : `%${codCombustible}%`]
                    );

                    if (tipoInterno.length === 0) continue;

                    const [ultimo] = await pool.query(`
                        SELECT precio FROM historial_precios
                        WHERE estacion_id = ? AND tipo_combustible_id = ?
                        ORDER BY fecha_registro DESC LIMIT 1
                    `, [estacionId, tipoInterno[0].id]);

                    if (ultimo.length && parseFloat(ultimo[0].precio) === precioActual) continue;

                    await pool.query(`
                        INSERT INTO historial_precios (estacion_id, tipo_combustible_id, precio, fecha_registro, fuente)
                        VALUES (?, ?, ?, NOW(), 'cne_v4')
                    `, [estacionId, tipoInterno[0].id, precioActual]);
                    preciosCont++;
                }
            }

            // Log de progreso cada 200 estaciones para no llenar la consola pero ver que avanza
            if (procesadas % 200 === 0) {
                console.log(` [CNE] Progreso: ${procesadas}/${totalCNE} estaciones procesadas...`);
            }
        }

        console.log(' --- RESUMEN FINAL CNE ---');
        console.log(` Estaciones Totales: ${totalCNE}`);
        console.log(` Nuevas Insertadas: ${insertadas}`);
        console.log(` Datos Actualizados: ${actualizadas}`);
        console.log(` Precios Nuevos/Cambiados: ${preciosCont}`);
        console.log(' --------------------------');

    } catch (err) {
        console.error(' [CNE] Error crítico en Sync:', err.message);
    }
};

module.exports = { syncEstaciones };