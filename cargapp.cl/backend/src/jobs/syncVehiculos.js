const axios = require('axios');
const mysql = require('mysql2/promise');
require('dotenv').config({ path: '../../.env' }); // Ajusta la ruta a tu .env si es necesario

const API_BASE = 'https://consumovehicular.minenergia.cl/backend/scv/vehiculo';
const USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

const fuelMap = {
    'COMBUSTION GASOLINA': 1,
    'COMBUSTION DIESEL': 2,
    'ELECTRICO PURO': 3, // ID para Eléctricos
    'PURO ELECTRICO': 3, 
    'HIBRIDO CON RECARGA EXTERIOR GASOLINA': 4, // ID para Hibridos
    'HIBRIDO SIN RECARGA EXTERIOR GASOLINA': 4,
    'HIBRIDO': 4,
    'FCEV (CELDA DE HIDROGENO) HIDROGENO': 5 // Hidrogeno
};

async function sync() {
    let connection;
    try {
        console.log('--- [VEHICULOS] Iniciando sincronizacion oficial ---');

        // Creamos una conexion manual ignorando el pool central para forzar 127.0.0.1
        connection = await mysql.createConnection({
            host: '127.0.0.1', // Forzamos IPv4 manualmente
            user: process.env.DB_USER || 'root',
            password: process.env.DB_PASSWORD || '123',
            database: process.env.DB_NAME || 'cargapp',
            port: 3306
        });

        console.log('[SISTEMA] Conexion manual a MariaDB (IPv4) establecida.');

        const { data: marcas } = await axios.get(`${API_BASE}/marcas`, { 
            headers: { 'User-Agent': USER_AGENT },
            timeout: 15000 
        });
        
        console.log(`[SISTEMA] ${marcas.length} marcas detectadas.`);

        for (const marca of marcas) {
            process.stdout.write(` > ${marca.nombre.toUpperCase()}... `);
            
            try {
                const { data: modelos } = await axios.get(`${API_BASE}/modelos?idMarca=${marca.idMarca}`, { 
                    headers: { 'User-Agent': USER_AGENT } 
                });

                for (const modelo of modelos) {
                    const { data: etiquetas } = await axios.get(`${API_BASE}/etiquetas?idModelo=${modelo.idModelo}`, { 
                        headers: { 'User-Agent': USER_AGENT } 
                    });

                    for (const etiqueta of etiquetas) {
                        const urlFinal = `${API_BASE}?criterio=idMarca:EQ:${marca.idMarca};idModelo:EQ:${modelo.idModelo};idEtiqueta:EQ:${etiqueta.idEtiqueta}&size=100`;
                        const { data: response } = await axios.get(urlFinal, { headers: { 'User-Agent': USER_AGENT } });

                        if (response.content && response.content.length > 0) {
                            for (const v of response.content) {
                                const marcaNorm = v.nombreMarca.trim().toUpperCase();
                                const modeloNorm = v.nombreModelo.trim().toUpperCase();
                                const detalleNorm = v.detalle ? v.detalle.trim().toUpperCase() : modeloNorm;
                                const fuelId = fuelMap[v.idEtiqueta] || null;

                                const sql = `
                                    INSERT INTO modelos_vehiculo (
                                        id_vehiculo_ministerio, marca, modelo, detalle, 
                                        transmision, cilindrada, rendimiento_ciudad, 
                                        rendimiento_carretera, rendimiento_mixto, 
                                        tipo_combustible_id, combustible_label, traccion
                                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                                    ON DUPLICATE KEY UPDATE 
                                        detalle = VALUES(detalle),
                                        rendimiento_ciudad = VALUES(rendimiento_ciudad),
                                        rendimiento_carretera = VALUES(rendimiento_carretera),
                                        rendimiento_mixto = VALUES(rendimiento_mixto),
                                        traccion = VALUES(traccion)
                                `;

                                await connection.execute(sql, [
                                    v.idVehiculo, marcaNorm, modeloNorm, detalleNorm,
                                    v.transmision || 'M', v.cilindrada || 0,
                                    v.rendimientoUrbano || 0, v.rendimientoCarretera || 0,
                                    v.rendimientoMixto || 0, fuelId, v.idEtiqueta, v.traccion || '4X2'
                                ]);
                            }
                        }
                    }
                }
                console.log('OK');
            } catch (err) {
                console.log(`ERROR (${err.message})`);
                continue;
            }
        }
        console.log('--- [VEHICULOS] Sincronizacion finalizada ---');
        process.exit(0);
    } catch (error) {
        console.error('\n[ERROR CRITICO]:', error.message);
        process.exit(1);
    } finally {
        if (connection) await connection.end();
    }
}

module.exports = { syncVehiculos: sync }; 