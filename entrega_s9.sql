-- USUARIO SYSTEM (Se usó Oracle XE local)

-- creación de usuarios

CREATE USER PRY2205_EFT   
IDENTIFIED BY MN_DBowner01 
DEFAULT TABLESPACE  USERS 
TEMPORARY TABLESPACE TEMP 
QUOTA 10M ON USERS; 

CREATE USER PRY2205_EFT_DES   
IDENTIFIED BY MN_DBtrabajador01 
DEFAULT TABLESPACE  USERS 
TEMPORARY TABLESPACE TEMP 
QUOTA 10M ON USERS;

CREATE USER PRY2205_EFT_CON   
IDENTIFIED BY MN_DBgeneral01 
DEFAULT TABLESPACE  USERS 
TEMPORARY TABLESPACE TEMP 
QUOTA 10M ON USERS;

-- creación de roles

CREATE ROLE PRY2205_ROL_D;
CREATE ROLE PRY2205_ROL_C;

-- Asignación de roles

GRANT PRY2205_ROL_D TO PRY2205_EFT_DES; 
GRANT PRY2205_ROL_C TO PRY2205_EFT_CON; 

-- Asignación de privilegios PRY2205_EFT

GRANT CREATE SESSION TO PRY2205_EFT;
GRANT CREATE TABLE TO PRY2205_EFT;
GRANT CREATE VIEW TO PRY2205_EFT;
GRANT CREATE SEQUENCE TO PRY2205_EFT;
GRANT CREATE SYNONYM TO PRY2205_EFT;
GRANT CREATE PUBLIC SYNONYM TO PRY2205_EFT;

-- Asignación de privilegios PRY2205_EFT_DES

GRANT CREATE SESSION TO PRY2205_ROL_D;

GRANT CREATE VIEW, CREATE PROFILE, CREATE USER TO PRY2205_ROL_D;

-- Asignación de privilegios PRY2205_EFT_CON

GRANT CREATE SESSION TO PRY2205_ROL_C;

-- usuario PRY2205_EFT

-- se ejecuta DDL Y DML 

-- creación de sinónimos públicos

CREATE OR REPLACE PUBLIC SYNONYM tabla_profesional FOR profesional;
CREATE OR REPLACE PUBLIC SYNONYM tabla_profesion FOR profesion;
CREATE OR REPLACE PUBLIC SYNONYM tabla_isapre FOR isapre;
CREATE OR REPLACE PUBLIC SYNONYM tabla_rangos_sueldos FOR rangos_sueldos;
CREATE OR REPLACE PUBLIC SYNONYM tabla_tipo_contrato FOR tipo_contrato;
CREATE OR REPLACE PUBLIC SYNONYM tabla_cartola_profesionales FOR cartola_profesionales;

-- otorga privilegios sobre sus tablas

GRANT SELECT ON tabla_profesional TO PRY2205_EFT_DES;
GRANT SELECT ON tabla_profesion TO PRY2205_EFT_DES;
GRANT SELECT ON tabla_isapre TO PRY2205_EFT_DES;
GRANT SELECT ON tabla_rangos_sueldos TO PRY2205_EFT_DES;
GRANT SELECT ON tabla_tipo_contrato TO PRY2205_EFT_DES;
GRANT INSERT ON tabla_cartola_profesionales TO PRY2205_EFT_DES;
GRANT SELECT ON tabla_cartola_profesionales TO PRY2205_EFT_DES WITH GRANT OPTION;

-- caso 2 creación informe

-- usuario PRY2205_EFT_DES

-- poblado de la tabla cartola_profesionales

INSERT INTO tabla_cartola_profesionales (
    rut_profesional,
    nombre_profesional,
    profesion,
    isapre,
    sueldo_base,
    porc_comision_profesional,
    valor_total_comision,
    porcentate_honorario,
    bono_movilizacion,
    total_pagar
)
SELECT
    RUT_PROFESIONAL,
    NOMBRE_PROFESIONAL,
    PROFESION,
    ISAPRE,
    SUELDO_BASE,
    PORC_COMISION_PROFESIONAL,
    VALOR_TOTAL_COMISION,
    PORCENTAJE_HONORARIO,
    BONO_MOVILIZACION,
    SUELDO_BASE + VALOR_TOTAL_COMISION + BONO_MOVILIZACION + PORCENTAJE_HONORARIO
FROM (
    SELECT 
        t1.rutprof AS RUT_PROFESIONAL,
        t1.nompro || ' ' || t1.apppro || ' ' || t1.apmpro AS NOMBRE_PROFESIONAL,
        t2.nomprofesion AS PROFESION,
        t3.nomisapre AS ISAPRE,
        t1.sueldo AS SUELDO_BASE,
        NVL(t1.comision, 0) AS PORC_COMISION_PROFESIONAL,
        NVL(t1.sueldo * t1.comision, 0) AS VALOR_TOTAL_COMISION,
        (t1.sueldo * t5.honor_pct) / 100 AS PORCENTAJE_HONORARIO,
        CASE 
            WHEN t4.nomtcontrato = 'Indefinido Jornada Completa' THEN 150000
            WHEN t4.nomtcontrato = 'Indefinido Jornada Parcial' THEN 120000
            WHEN t4.nomtcontrato = 'Plazo fijo' THEN 60000
            WHEN t4.nomtcontrato = 'Honorarios' THEN 50000
            ELSE 0
        END AS BONO_MOVILIZACION
    FROM
        tabla_profesional t1 
        JOIN tabla_profesion t2 ON t1.idprofesion = t2.idprofesion
        JOIN tabla_isapre t3 ON t1.idisapre = t3.idisapre
        JOIN tabla_tipo_contrato t4 ON t1.idtcontrato = t4.idtcontrato
        JOIN tabla_rangos_sueldos t5 ON t1.sueldo BETWEEN t5.s_min AND t5.s_max
    )
ORDER BY
    PROFESION ASC,
    SUELDO_BASE DESC,
    PORC_COMISION_PROFESIONAL ASC,
    RUT_PROFESIONAL ASC;

COMMIT;

-- le otorga el privilegio a PRY2205_EFT_CON

GRANT SELECT ON tabla_cartola_profesionales TO PRY2205_EFT_CON;


-- caso 3 Optimización de sentencias SQL

-- usuario PRY2205_EFT

-- creacion de vista

CREATE OR REPLACE VIEW VW_EMPRESAS_ASESORADAS AS
SELECT 
    RUT_EMPRESA,
    NOMBRE_EMPRESA,
    IVA,
    ANIOS_EXISTENCIA,
    TOTAL_ASESORIAS_ANUALES,
    ROUND((TOTAL_ASESORIAS_ANUALES * IVA) / 100) AS DEVOLUCION_IVA,
    CASE 
        WHEN TOTAL_ASESORIAS_ANUALES > 5 THEN 'CLIENTE PREMIUM'
        WHEN TOTAL_ASESORIAS_ANUALES BETWEEN 3 AND 5 THEN 'CLIENTE'
        WHEN TOTAL_ASESORIAS_ANUALES < 3 THEN 'CLIENTE POCO CONCURRIDO'
    END AS TIPO_CLIENTE,
    CASE 
        WHEN TOTAL_ASESORIAS_ANUALES > 5 THEN
            CASE 
                WHEN TOTAL_ASESORIAS_ANUALES >= 7 THEN '1 ASESORIA GRATIS'
                WHEN TOTAL_ASESORIAS_ANUALES < 7 THEN '1 ASESORIA 40% DE DESCUENTO'
            END
        WHEN TOTAL_ASESORIAS_ANUALES BETWEEN 3 AND 5 THEN
            CASE 
                WHEN TOTAL_ASESORIAS_ANUALES = 5 THEN '1 ASESORÍA 30% DE DESCUENTO'
                WHEN TOTAL_ASESORIAS_ANUALES < 5 THEN '1 ASESORÍA 20% DE DESCUENTO'
            END
        WHEN TOTAL_ASESORIAS_ANUALES < 3 THEN 'CAPTAR CLIENTE'
    END AS CORRESPONDE
FROM(
    SELECT
        TO_CHAR(e.rut_empresa, '999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || e.dv_empresa AS RUT_EMPRESA,
        UPPER(e.nomempresa) AS NOMBRE_EMPRESA,
        e.iva_declarado AS IVA,
        FLOOR(MONTHS_BETWEEN(SYSDATE, e.fecha_iniciacion_actividades) / 12) AS ANIOS_EXISTENCIA,
        FLOOR(COUNT(a.idempresa)/12) AS TOTAL_ASESORIAS_ANUALES
    FROM
        empresa e
        JOIN asesoria a ON e.idempresa = a.idempresa
    WHERE
        EXTRACT(YEAR FROM a.fin) = EXTRACT(YEAR FROM SYSDATE) - 1
    GROUP BY
        TO_CHAR(e.rut_empresa, '999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || e.dv_empresa,
        e.nomempresa,
        e.iva_declarado,
        FLOOR(MONTHS_BETWEEN(SYSDATE, e.fecha_iniciacion_actividades) / 12)
    )
ORDER BY NOMBRE_EMPRESA;

-- creacion de sinonimo para la vista

CREATE PUBLIC SYNONYM VISTA_EMPRESAS_ASESORADAS FOR VW_EMPRESAS_ASESORADAS;

-- otorgar privilegios a PRY2205_EFT_CON

GRANT SELECT ON VISTA_EMPRESAS_ASESORADAS TO PRY2205_EFT_CON;

-- indices para optimización de la vista

CREATE INDEX IDX_ASESORIA_JOIN_FIN ON asesoria (idempresa, fin);
CREATE INDEX IDX_ASESORIA_ANIO_FIN ON asesoria (EXTRACT(YEAR FROM fin));

