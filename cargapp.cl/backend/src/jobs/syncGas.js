require('dotenv').config({ path: '../../.env' });	
const axios = require('axios');
const pool = require('../models/db'); // Ajustado a tu ruta de modelos
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
        if (token) console.log(' [CNE-GAS] Token obtenido exitosamente.');
        return token;
    } catch (err) {
        console.error(' [CNE-GAS] Error en Login:', err.message);
        return null;
    }
};

const syncGas = async () => {
    const token = await getFreshToken();
    if (!token) return;

    const headers = { 'Authorization': `Bearer ${token}` };
    // Definimos los dos tipos de datos que vamos a traer
    const tareas = [
        { url: '/api/v3/combustible/calefaccion/callcenters', tag: 'CALLCENTER', listaKey: 'callcenters' },
        { url: '/api/v3/combustible/calefaccion/puntosdeventa', tag: 'LOCAL_FISICO', listaKey: 'normal' }
    ];

    try {
        console.log(' --- [INICIO] Sincronización Global GLP ---');

        for (const tarea of tareas) {
            console.log(` > Procesando ${tarea.tag}...`);
            const response = await axios.get(`${process.env.CNE_API_URL}${tarea.url}`, { headers });
            const empresas = response.data;
            let iteracion = 0;

            for (const key in empresas) {
                const e = empresas[key];
                
                // 1. Marca
                const nombreMarca = (e.marca || e.nombre_empresa).toUpperCase();
                await pool.query(
                    "INSERT INTO gas_marcas (nombre, logo_url) VALUES (?, ?) ON DUPLICATE KEY UPDATE logo_url=VALUES(logo_url)",
                    [nombreMarca, e.logo_svg]
                );
                const [[marca]] = await pool.query("SELECT id FROM gas_marcas WHERE nombre = ?", [nombreMarca]);

                // 2. Punto de Venta
                const nombreLocal = tarea.tag === 'CALLCENTER' ? `${e.nombre_empresa} (Callcenter)` : e.nombre_empresa;
                await pool.query(
                    `INSERT INTO gas_puntos_venta (marca_id, nombre, direccion, comuna_id, telefono, latitud, longitud) 
                     VALUES (?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE telefono=VALUES(telefono), latitud=VALUES(latitud), longitud=VALUES(longitud)`,
                    [marca.id, nombreLocal, e.direccion_empresa, e.id_comuna, e.fono_empresa, e.ubicacion.latitud, e.ubicacion.longitud]
                );
                const [[punto]] = await pool.query("SELECT id FROM gas_puntos_venta WHERE nombre = ? AND direccion = ?", [nombreLocal, e.direccion_empresa]);

                // 3. Precios
                const listadoPrecios = e[tarea.listaKey] || [];
                for (const p of listadoPrecios) {
                    const nombreTipo = `${p.tamano}${p.medida} ${p.tipo_gas || 'normal'}`.trim();
                    
                    await pool.query("INSERT INTO gas_tipos (nombre) VALUES (?) ON DUPLICATE KEY UPDATE nombre=VALUES(nombre)", [nombreTipo]);
                    const [[tipo]] = await pool.query("SELECT id FROM gas_tipos WHERE nombre = ?", [nombreTipo]);

                    await pool.query(
                        "INSERT INTO gas_precios (punto_venta_id, tipo_gas_id, precio) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE precio = VALUES(precio)",
                        [punto.id, tipo.id, p.precio]
                    );
                }

                iteracion++;
                if (iteracion % 50 === 0) console.log(`   ... ${iteracion} empresas procesadas`);
            }
            console.log(` > ${tarea.tag} completado: ${iteracion} registros.`);
        }

        console.log(' --- [EXITO] Sincronización Global GLP terminada ---');

    } catch (err) {
        console.error(' [CNE-GAS] Error Crítico:', err.message);
    } finally {
        // Solo cerramos el proceso si se ejecuta directamente desde la terminal
        if (require.main === module) {
            process.exit();
        }
    }
};

// Ejecución manual
if (require.main === module) {
    syncGas();
}

module.exports = { syncGas };