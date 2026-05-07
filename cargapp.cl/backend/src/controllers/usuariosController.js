const pool   = require('../models/db')
const bcrypt = require('bcrypt')
const jwt    = require('jsonwebtoken')
require('dotenv').config()

// Registro
const registro = async (req, res) => {
  const { email, contrasena, nombre_completo, telefono } = req.body

  if (!email || !contrasena) {
    return res.status(400).json({ error: 'Email y contraseña son requeridos' })
  }

  try {
    const [existe] = await pool.query(
      'SELECT id FROM usuarios WHERE email = ?', [email]
    )
    if (existe.length) {
      return res.status(409).json({ error: 'El email ya está registrado' })
    }

    const hash = await bcrypt.hash(contrasena, 10)

    const [result] = await pool.query(`
      INSERT INTO usuarios (email, contrasena_hash, nombre_completo, telefono, creado_en)
      VALUES (?, ?, ?, ?, NOW())
    `, [email, hash, nombre_completo || null, telefono || null])

    const token = jwt.sign(
      { id: result.insertId, email },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    )

    res.status(201).json({
      mensaje: 'Usuario creado correctamente',
      token,
      usuario: {
        id: result.insertId,
        email,
        nombre_completo: nombre_completo || null,
        telefono: telefono || null,
        es_premium: false,
        reputacion: 0
      }
    })

  } catch (err) {
    console.error(err)
    res.status(500).json({ error: 'Error al registrar usuario' })
  }
}

// Login
const login = async (req, res) => {
  const { email, contrasena } = req.body

  if (!email || !contrasena) {
    return res.status(400).json({ error: 'Email y contraseña son requeridos' })
  }

  try {
    const [rows] = await pool.query(
      'SELECT * FROM usuarios WHERE email = ? AND activo = 1', [email]
    )

    if (!rows.length) {
      return res.status(401).json({ error: 'Credenciales inválidas' })
    }

    const usuario = rows[0]
    const valido  = await bcrypt.compare(contrasena, usuario.contrasena_hash)

    if (!valido) {
      return res.status(401).json({ error: 'Credenciales inválidas' })
    }

    // Actualizar último acceso
    await pool.query(
      'UPDATE usuarios SET ultimo_acceso = NOW() WHERE id = ?', [usuario.id]
    )

    const token = jwt.sign(
      { id: usuario.id, email: usuario.email, es_premium: usuario.es_premium },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    )

    res.json({
      token,
      usuario: {
        id       : usuario.id,
        email    : usuario.email,
        nombre   : usuario.nombre_completo,
        telefono : usuario.telefono,
        premium  : usuario.es_premium,
        reputacion: usuario.puntos_reputacion
      }
    })

  } catch (err) {
    console.error(err)
    res.status(500).json({ error: 'Error al iniciar sesión' })
  }
}

// Perfil
const getPerfil = async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT 
        u.id, u.email, u.nombre_completo, u.telefono, u.puntos_reputacion, u.es_premium, u.creado_en,
        u.ciudad_id,
        c.nombre AS ciudad,
        r.id AS region_id,
        r.nombre AS region
       FROM usuarios u
       LEFT JOIN ciudades c ON c.id = u.ciudad_id
       LEFT JOIN regiones r ON r.id = c.region_id
       WHERE u.id = ?`, [req.usuarioId]
    )
    if (!rows.length) return res.status(404).json({ error: 'Usuario no encontrado' })
    res.json(rows[0])
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener perfil' })
  }
}

const actualizarPerfil = async (req, res) => {
  const { nombre_completo, telefono, ciudad_id } = req.body

  if (nombre_completo == null && telefono == null && ciudad_id == null) {
    return res.status(400).json({ error: 'No hay datos para actualizar' })
  }

  const updates = []
  const params = []

  if (nombre_completo !== null) {
    updates.push('nombre_completo = ?')
    params.push(nombre_completo || null)
  }

  if (telefono !== null) {
    updates.push('telefono = ?')
    params.push(telefono || null)
  }

  if (ciudad_id !== null) {
    updates.push('ciudad_id = ?')
    params.push(ciudad_id || null)
  }

  params.push(req.usuarioId)

  try {
    await pool.query(`UPDATE usuarios SET ${updates.join(', ')} WHERE id = ?`, params)

    const [rows] = await pool.query(
      `SELECT 
        u.id, u.email, u.nombre_completo, u.telefono, u.puntos_reputacion, u.es_premium,
        u.ciudad_id,
        c.nombre AS ciudad,
        r.id AS region_id,
        r.nombre AS region
       FROM usuarios u
       LEFT JOIN ciudades c ON c.id = u.ciudad_id
       LEFT JOIN regiones r ON r.id = c.region_id
       WHERE u.id = ?`,
      [req.usuarioId]
    )

    res.json(rows[0])
  } catch (err) {
    console.error(err)
    res.status(500).json({ error: 'Error al actualizar perfil' })
  }
}

// Obtener todas las regiones
const getRegiones = async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT id, nombre, codigo FROM regiones ORDER BY nombre'
    )
    res.json(rows)
  } catch (err) {
    console.error(err)
    res.status(500).json({ error: 'Error al obtener regiones' })
  }
}

// Obtener ciudades por región
const getCiudadesPorRegion = async (req, res) => {
  const { regionId } = req.params
  
  if (!regionId) {
    return res.status(400).json({ error: 'regionId es requerido' })
  }

  try {
    const [rows] = await pool.query(
      'SELECT id, nombre FROM ciudades WHERE region_id = ? ORDER BY nombre',
      [regionId]
    )
    res.json(rows)
  } catch (err) {
    console.error(err)
    res.status(500).json({ error: 'Error al obtener ciudades' })
  }
}

module.exports = { registro, login, getPerfil, actualizarPerfil, getRegiones, getCiudadesPorRegion }