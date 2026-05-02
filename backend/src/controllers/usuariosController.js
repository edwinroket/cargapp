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
        es_premium: false
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
      `SELECT id, email, nombre_completo, telefono, puntos_reputacion, es_premium, creado_en
       FROM usuarios WHERE id = ?`, [req.usuarioId]
    )
    if (!rows.length) return res.status(404).json({ error: 'Usuario no encontrado' })
    res.json(rows[0])
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener perfil' })
  }
}

module.exports = { registro, login, getPerfil }