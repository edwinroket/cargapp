const jwt = require('jsonwebtoken')
require('dotenv').config()

const verificarToken = (req, res, next) => {
  const header = req.headers['authorization']
  const token  = header && header.split(' ')[1]

  if (!token) {
    return res.status(401).json({ error: 'Token requerido' })
  }

  try {
    const decoded  = jwt.verify(token, process.env.JWT_SECRET)
    req.usuarioId  = decoded.id
    req.esPremium  = decoded.es_premium
    next()
  } catch (err) {
    return res.status(403).json({ error: 'Token inválido o expirado' })
  }
}

module.exports = { verificarToken }