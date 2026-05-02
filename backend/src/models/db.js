const mysql = require('mysql2/promise')
require('dotenv').config()

const pool = mysql.createPool({
  host     : process.env.DB_HOST,
  port     : process.env.DB_PORT,
  user     : process.env.DB_USER,
  password : process.env.DB_PASSWORD,
  database : process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit   : 10,
})

pool.getConnection()
  .then(conn => {
    console.log('BD MariaDB conectada correctamente')
    conn.release()
  })
  .catch(err => {
    console.error('Error conectando a la BD:', err.message)
  })

module.exports = pool