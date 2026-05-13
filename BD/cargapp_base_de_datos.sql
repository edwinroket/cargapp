-- ============================================================
--  CargApp — Script de creación de base de datos
--  Motor: MySQL 8.0+ / MariaDB
--  Codificación: UTF-8
--  Ejecutar en localhost con: mysql -u root -p < cargapp_base_de_datos.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS cargapp
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_spanish_ci;

USE cargapp;

-- ============================================================
--  TABLA: tipos_combustible
-- ============================================================
CREATE TABLE tipos_combustible (
  id            INT             NOT NULL AUTO_INCREMENT,
  nombre        VARCHAR(50)     NOT NULL COMMENT 'Ej: Gasolina 95, Diésel, Parafina',
  categoria     ENUM('bencina','gas','parafina','electrico','otro') NOT NULL DEFAULT 'bencina',
  activo        TINYINT(1)      NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_nombre (nombre)
) ENGINE=InnoDB COMMENT='Tipos de combustible disponibles en la app';

-- ============================================================
--  TABLA: estaciones
--  Sincronizadas desde bencinaenlinea.cl
-- ============================================================
CREATE TABLE estaciones (
  id                  INT             NOT NULL AUTO_INCREMENT,
  cne_id              INT             NOT NULL COMMENT 'ID único en bencinaenlinea.cl',
  nombre              VARCHAR(150)    NOT NULL,
  marca               VARCHAR(80)     NOT NULL,
  direccion           VARCHAR(255)    NOT NULL,
  latitud             DECIMAL(10, 7)  NOT NULL,
  longitud            DECIMAL(10, 7)  NOT NULL,
  region              VARCHAR(100)    NOT NULL,
  comuna              VARCHAR(100)    NOT NULL,
  horario             VARCHAR(100)    NULL,
  metodos_pago        VARCHAR(200)    NULL,
  tiene_bano          TINYINT(1)      NOT NULL DEFAULT 0,
  tiene_tienda        TINYINT(1)      NOT NULL DEFAULT 0,
  tiene_lubricentro   TINYINT(1)      NOT NULL DEFAULT 0,
  activa              TINYINT(1)      NOT NULL DEFAULT 1,
  ultima_sync_cne     DATETIME        NULL,
  creado_en           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_cne_id (cne_id),
  INDEX idx_region (region),
  INDEX idx_comuna (comuna),
  INDEX idx_marca (marca),
  INDEX idx_coordenadas (latitud, longitud)
) ENGINE=InnoDB COMMENT='Estaciones de servicio desde bencinaenlinea.cl';

-- ============================================================
--  TABLA: historial_precios
-- ============================================================
CREATE TABLE historial_precios (
  id                  INT             NOT NULL AUTO_INCREMENT,
  estacion_id         INT             NOT NULL,
  tipo_combustible_id INT             NOT NULL,
  precio              DECIMAL(8, 1)   NOT NULL,
  fecha_registro      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fuente              ENUM('cne','reporte_usuario') NOT NULL DEFAULT 'cne',
  PRIMARY KEY (id),
  FOREIGN KEY fk_hp_estacion (estacion_id) REFERENCES estaciones (id) ON DELETE CASCADE,
  FOREIGN KEY fk_hp_combustible (tipo_combustible_id) REFERENCES tipos_combustible (id),
  INDEX idx_estacion_fecha (estacion_id, fecha_registro),
  INDEX idx_combustible_fecha (tipo_combustible_id, fecha_registro)
) ENGINE=InnoDB COMMENT='Historial de precios por estación y combustible';

-- ============================================================
--  TABLA: modelos_vehiculo
--  Desde consumovehicular.cl
-- ============================================================
CREATE TABLE modelos_vehiculo (
  id                  INT             NOT NULL AUTO_INCREMENT,
  marca               VARCHAR(80)     NOT NULL,
  modelo              VARCHAR(100)    NOT NULL,
  anio                YEAR            NOT NULL,
  rendimiento_oficial FLOAT           NOT NULL COMMENT 'km/L oficial',
  tipo_combustible_id INT             NULL,
  PRIMARY KEY (id),
  FOREIGN KEY fk_mv_combustible (tipo_combustible_id) REFERENCES tipos_combustible (id),
  INDEX idx_marca_modelo (marca, modelo)
) ENGINE=InnoDB COMMENT='Modelos de vehículos con rendimiento oficial';

-- ============================================================
--  TABLA: usuarios
-- ============================================================
CREATE TABLE usuarios (
  id                  INT             NOT NULL AUTO_INCREMENT,
  email               VARCHAR(150)    NOT NULL,
  contrasena_hash     VARCHAR(255)    NOT NULL COMMENT 'Hash bcrypt',
  nombre_completo     VARCHAR(150)    NULL,
  telefono            VARCHAR(20)     NULL,
  puntos_reputacion   INT             NOT NULL DEFAULT 0,
  es_premium          TINYINT(1)      NOT NULL DEFAULT 0,
  token_push          VARCHAR(255)    NULL     COMMENT 'Token FCM',
  activo              TINYINT(1)      NOT NULL DEFAULT 1,
  creado_en           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ultimo_acceso       DATETIME        NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_email (email),
  INDEX idx_premium (es_premium)
) ENGINE=InnoDB COMMENT='Usuarios registrados de la app';

-- ============================================================
--  TABLA: vehiculos
-- ============================================================
CREATE TABLE vehiculos (
  id                  INT             NOT NULL AUTO_INCREMENT,
  usuario_id          INT             NOT NULL,
  modelo_id           INT             NULL,
  alias               VARCHAR(80)     NULL,
  marca_manual        VARCHAR(80)     NULL,
  modelo_manual       VARCHAR(100)    NULL,
  anio_manual         YEAR            NULL,
  rendimiento_km_l    FLOAT           NOT NULL,
  tipo_combustible_id INT             NOT NULL,
  es_principal        TINYINT(1)      NOT NULL DEFAULT 0,
  creado_en           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY fk_v_usuario (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE,
  FOREIGN KEY fk_v_modelo (modelo_id) REFERENCES modelos_vehiculo (id) ON DELETE SET NULL,
  FOREIGN KEY fk_v_combustible (tipo_combustible_id) REFERENCES tipos_combustible (id)
) ENGINE=InnoDB COMMENT='Vehículos registrados por cada usuario';

-- ============================================================
--  TABLA: reportes
--  Precios reportados por la comunidad (crowdsourcing)
-- ============================================================
CREATE TABLE reportes (
  id                  INT             NOT NULL AUTO_INCREMENT,
  usuario_id          INT             NOT NULL,
  estacion_id         INT             NOT NULL,
  tipo_combustible_id INT             NOT NULL,
  precio_reportado    DECIMAL(8, 1)   NOT NULL,
  votos_positivos     INT             NOT NULL DEFAULT 0,
  votos_negativos     INT             NOT NULL DEFAULT 0,
  estado              ENUM('pendiente','verificado','rechazado') NOT NULL DEFAULT 'pendiente',
  creado_en           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY fk_r_usuario (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE,
  FOREIGN KEY fk_r_estacion (estacion_id) REFERENCES estaciones (id) ON DELETE CASCADE,
  FOREIGN KEY fk_r_combustible (tipo_combustible_id) REFERENCES tipos_combustible (id),
  INDEX idx_estacion_estado (estacion_id, estado),
  INDEX idx_usuario_reporte (usuario_id)
) ENGINE=InnoDB COMMENT='Precios reportados por la comunidad';

-- ============================================================
--  TABLA: votos_reporte
-- ============================================================
CREATE TABLE votos_reporte (
  id                  INT             NOT NULL AUTO_INCREMENT,
  reporte_id          INT             NOT NULL,
  usuario_id          INT             NOT NULL,
  voto                ENUM('positivo','negativo') NOT NULL,
  creado_en           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_voto_unico (reporte_id, usuario_id),
  FOREIGN KEY fk_vr_reporte (reporte_id) REFERENCES reportes (id) ON DELETE CASCADE,
  FOREIGN KEY fk_vr_usuario (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Control de votos por reporte';

-- ============================================================
--  TABLA: alertas
-- ============================================================
CREATE TABLE alertas (
  id                  INT             NOT NULL AUTO_INCREMENT,
  usuario_id          INT             NOT NULL,
  tipo_combustible_id INT             NOT NULL,
  estacion_id         INT             NULL     COMMENT 'NULL = alerta por radio',
  precio_umbral       DECIMAL(8, 1)   NOT NULL,
  radio_km            INT             NOT NULL DEFAULT 5,
  latitud_usuario     DECIMAL(10, 7)  NULL,
  longitud_usuario    DECIMAL(10, 7)  NULL,
  activa              TINYINT(1)      NOT NULL DEFAULT 1,
  ultima_notificacion DATETIME        NULL,
  creado_en           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY fk_a_usuario (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE,
  FOREIGN KEY fk_a_combustible (tipo_combustible_id) REFERENCES tipos_combustible (id),
  FOREIGN KEY fk_a_estacion (estacion_id) REFERENCES estaciones (id) ON DELETE SET NULL,
  INDEX idx_alertas_activas (activa, tipo_combustible_id)
) ENGINE=InnoDB COMMENT='Alertas de precio configuradas por usuarios';

-- ============================================================
--  TABLA: estaciones_favoritas
-- ============================================================
CREATE TABLE estaciones_favoritas (
  id                  INT             NOT NULL AUTO_INCREMENT,
  usuario_id          INT             NOT NULL,
  estacion_id         INT             NOT NULL,
  creado_en           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_favorito (usuario_id, estacion_id),
  FOREIGN KEY fk_ef_usuario (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE,
  FOREIGN KEY fk_ef_estacion (estacion_id) REFERENCES estaciones (id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Estaciones marcadas como favoritas';

-- ============================================================
--  TABLA: descuentos
--  Sincronizado diariamente desde bencinabarata.cl (Supabase)
-- ============================================================
CREATE TABLE descuentos (
  id               INT          NOT NULL AUTO_INCREMENT,
  origen           VARCHAR(50)  NOT NULL COMMENT 'Copec, Shell, Aramco, Petrobras',
  convenio         VARCHAR(150) NOT NULL COMMENT 'Banco, tarjeta o app',
  tipo             VARCHAR(80)  NOT NULL COMMENT 'Tarjetas Bancarias, App/Digital, etc.',
  dia              VARCHAR(20)  NOT NULL COMMENT 'lunes, martes... o todos los dias',
  descuento_num    DECIMAL(8,1) NULL     COMMENT 'Descuento en pesos por litro',
  descuento_texto  VARCHAR(100) NULL     COMMENT 'Texto original ej: Desde $50/lt',
  condicion        VARCHAR(200) NULL     COMMENT 'Como activar el descuento',
  tope_mensual     VARCHAR(100) NULL,
  notas            TEXT         NULL,
  fuente_url       VARCHAR(255) NULL,
  vigencia_hasta   DATE         NULL,
  activo           TINYINT(1)   NOT NULL DEFAULT 1,
  ultima_sync      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_origen (origen),
  INDEX idx_dia    (dia),
  INDEX idx_activo (activo)
) ENGINE=InnoDB COMMENT='Descuentos por tarjeta y convenio desde bencinabarata.cl';

-- ============================================================
--  DATOS INICIALES: tipos de combustible
-- ============================================================
INSERT INTO tipos_combustible (nombre, categoria) VALUES
  ('Gasolina 93',   'bencina'),
  ('Gasolina 95',   'bencina'),
  ('Gasolina 97',   'bencina'),
  ('Diesel',        'bencina'),
  ('Kerosene',      'bencina'),
  ('Gas licuado',   'gas'),
  ('Gas natural',   'gas'),
  ('Parafina',      'parafina'),
  ('Electrico',     'electrico');

-- ============================================================
--  FIN DEL SCRIPT
--  Para verificar: SHOW TABLES; / DESCRIBE nombre_tabla;
-- ============================================================