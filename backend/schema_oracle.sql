-- ═══════════════════════════════════════════════════════════════
-- schema_oracle.sql — DDL de producción (Oracle Cloud Free Tier)
-- ═══════════════════════════════════════════════════════════════
-- Espejo exacto del esquema SQLite de desarrollo (backend/db.py),
-- traducido a tipos y convenciones Oracle. Misma estructura lógica,
-- misma lógica de negocio en routes/ y models.py — solo cambia esta
-- capa de definición de datos y el driver de conexión (oracledb en
-- vez de sqlite3).
--
-- No se ejecuta en la demo local (Etapa 2). Es la evidencia de que
-- el paso a producción (piloto real, si se avanza a la etapa final)
-- ya está diseñado y no requiere rediseñar el sistema desde cero.

CREATE TABLE zones (
    id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name    VARCHAR2(100) NOT NULL
);

CREATE TABLE cameras (
    id           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name         VARCHAR2(100) NOT NULL,
    source_url   VARCHAR2(500) NOT NULL,   -- URL RTSP en producción
    zone_id      NUMBER NOT NULL REFERENCES zones(id),
    is_active    NUMBER(1) DEFAULT 1 NOT NULL,
    preview_url  VARCHAR2(500)
);

CREATE TABLE alerts (
    id                NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    camera_id         NUMBER NOT NULL REFERENCES cameras(id),
    zone_id           NUMBER NOT NULL REFERENCES zones(id),
    track_id          NUMBER,
    vehicle_type      VARCHAR2(50) NOT NULL,   -- 'truck' | 'bus' | 'car'
    confidence        NUMBER(4,3) DEFAULT 0 NOT NULL,  -- 0.000 a 1.000
    detected_at       TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_seconds  NUMBER DEFAULT 0 NOT NULL,
    status            VARCHAR2(20) DEFAULT 'active' NOT NULL,
                      -- 'active' | 'resolved' | 'escalated'
    officer_notes     VARCHAR2(1000),
    resolved_at       TIMESTAMP WITH TIME ZONE,
    thumbnail_url     VARCHAR2(500)
);

-- Índices para las consultas más frecuentes del backend
-- (GET /api/alerts?status=active y el upsert por track_id).
CREATE INDEX idx_alerts_status ON alerts(status);
CREATE INDEX idx_alerts_track_active ON alerts(track_id, status);

-- ── Medidas de seguridad a nivel de base de datos ────────────────
-- 1. Usuario de aplicación con permisos mínimos: solo SELECT/INSERT/
--    UPDATE sobre estas 3 tablas, sin DROP/ALTER ni acceso a otros
--    esquemas del Oracle Cloud tenant.
-- 2. Conexión cifrada obligatoria (Oracle Wallet / TLS), nunca texto
--    plano — Oracle Cloud Free Tier lo exige por defecto (mTLS).
-- 3. Credenciales fuera del código: se leen de variables de entorno
--    (DB_USER, DB_PASSWORD, DB_SERVICE_NAME en .env), nunca
--    hardcodeadas ni versionadas en git — mismo patrón que ya usa
--    ML_API_KEY en el backend actual.
-- 4. Foreign keys con ON DELETE restringido implícito: no se puede
--    borrar una cámara o zona con alertas asociadas sin decisión
--    explícita, evitando huérfanos silenciosos en la auditoría.
