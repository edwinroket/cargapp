require('dotenv').config({ path: '../../.env' });	
const axios = require('axios');
const pool = require('../models/db');

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
    const tareas = [
        { url: '/api/v3/combustible/calefaccion/callcenters', tag: 'CALLCENTER', listaKey: 'callcenters' },
        { url: '/api/v3/combustible/calefaccion/puntosdeventa', tag: 'LOCAL_FISICO', listaKey: 'normal' }
    ];

    try {
        console.log(' --- [INICIO] Sincronización Global GLP Sucursales ---');

        for (const tarea of tareas) {
            console.log(` > Solicitando datos de ${tarea.tag}...`);
            const response = await axios.get(`${process.env.CNE_API_URL}${tarea.url}`, { headers });
            
            const empresasLista = Object.values(response.data || {});
            let sucursalesProcesadas = 0;

            for (const e of empresasLista) {
                if (!e) continue;

                // 1. Registrar o actualizar la Marca Base
                const nombreMarca = (e.marca || e.nombre_empresa || 'S/M').toUpperCase();
                await pool.query(
                    "INSERT INTO gas_marcas (nombre, logo_url) VALUES (?, ?) ON DUPLICATE KEY UPDATE logo_url=VALUES(logo_url)",
                    [nombreMarca, e.logo_svg || null]
                );
                const [[marca]] = await pool.query("SELECT id FROM gas_marcas WHERE nombre = ?", [nombreMarca]);

                // Obtener el listado interno de locales reales de esta empresa
                const listadoSucursales = e[tarea.listaKey] || [];

                for (const s of listadoSucursales) {
                    // 2. Extraer datos específicos de la sucursal/local minorista
                    // Si es Callcenter usamos el nombre de la empresa, si es local físico la CNE a veces manda 'nombre_fantasia' o el de la empresa
                    let nombreLocal = s.nombre_fantasia || e.nombre_empresa;
                    if (tarea.tag === 'CALLCENTER') {
                        nombreLocal = `${nombreLocal} (Callcenter)`;
                    }

                    const direccionLocal = s.direccion || e.direccion_empresa || 'Dirección no informada';
                    const comunaIdLocal = s.id_comuna || e.id_comuna || null;
                    const telefonoLocal = s.telefono || e.fono_empresa || 'No informado';
                    
                    // Extraer coordenadas de la sucursal (pueden venir directo en 's' o dentro de 's.ubicacion')
                    const latitudLocal = parseFloat(s.latitud || s.ubicacion?.latitud || e.ubicacion?.latitud || 0);
                    const longitudLocal = parseFloat(s.longitud || s.ubicacion?.longitud || e.ubicacion?.longitud || 0);

                    // Insertar Punto de Venta Minorista
                    await pool.query(
                        `INSERT INTO gas_puntos_venta (marca_id, nombre, direccion, comuna_id, telefono, latitud, longitud) 
                         VALUES (?, ?, ?, ?, ?, ?, ?) 
                         ON DUPLICATE KEY UPDATE telefono=VALUES(telefono), latitud=VALUES(latitud), longitud=VALUES(longitud)`,
                        [marca.id, nombreLocal, direccionLocal, comunaIdLocal, telefonoLocal.substring(0, 95), latitudLocal, longitudLocal]
                    );

                    // Rescatamos el ID de la sucursal que acabamos de guardar/actualizar
                    const [[punto]] = await pool.query(
                        "SELECT id FROM gas_puntos_venta WHERE nombre = ? AND direccion = ? AND comuna_id = ?", 
                        [nombreLocal, direccionLocal, comunaIdLocal]
                    );

                    // 3. Registrar el Precio del cilindro asociado a este punto de venta específico
                    const nombreTipo = `${s.tamano}${s.medida} ${s.tipo_gas || 'normal'}`.trim();
                    
                    await pool.query("INSERT INTO gas_tipos (nombre) VALUES (?) ON DUPLICATE KEY UPDATE nombre=VALUES(nombre)", [nombreTipo]);
                    const [[tipo]] = await pool.query("SELECT id FROM gas_tipos WHERE nombre = ?", [nombreTipo]);

                    await pool.query(
                        `INSERT INTO gas_precios (punto_venta_id, tipo_gas_id, precio) 
                         VALUES (?, ?, ?) 
                         ON DUPLICATE KEY UPDATE precio = VALUES(precio), fecha_actualizacion = NOW()`,
                        [punto.id, tipo.id, s.precio]
                    );

                    sucursalesProcesadas++;
                }
            }
            console.log(` > ${tarea.tag} completado de forma síncrona. Total sucursales: ${sucursalesProcesadas}`);
        }

        console.log(' --- [EXITO] Sincronización Global GLP terminada ---');

    } catch (err) {
        console.error(' [CNE-GAS] Error Crítico:', err.message);
    } finally {
        if (require.main === module) {
            console.log(' [SISTEMA] Cerrando conexiones de la base de datos...');
            await pool.end(); 
            console.log(' [SISTEMA] Proceso finalizado con éxito.');
        }
    }
};

if (require.main === module) {
    syncGas();
}

module.exports = { syncGas };