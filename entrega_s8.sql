-- como system

CREATE ROLE PRY2205_ROL_D;
CREATE ROLE PRY2205_ROL_P;

GRANT CREATE SESSION,
      CREATE TABLE,
      CREATE VIEW,
      CREATE SEQUENCE,
      CREATE PROCEDURE,
      CREATE TRIGGER,
      CREATE SYNONYM,
      CREATE PUBLIC SYNONYM
TO PRY2205_ROL_D;

CREATE USER PRY2205_USER1
IDENTIFIED BY "PRY2205_1"
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON USERS;

CREATE USER PRY2205_USER2
IDENTIFIED BY "PRY2205_2"
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON USERS;

GRANT PRY2205_ROL_D TO PRY2205_USER1;

-- una vez creado el schema poblado como system

GRANT CREATE SESSION,
      CREATE TABLE,
      CREATE SEQUENCE,
      CREATE TRIGGER
TO PRY2205_ROL_P;

GRANT SELECT ON PRY2205_USER1.libro TO PRY2205_ROL_P;
GRANT SELECT ON PRY2205_USER1.ejemplar TO PRY2205_ROL_P;
GRANT SELECT ON PRY2205_USER1.prestamo TO PRY2205_ROL_P;

GRANT PRY2205_ROL_P TO PRY2205_USER2;


-- caso 2

-- sinonimos como user_1

CREATE PUBLIC SYNONYM libro
FOR PRY2205_USER1.libro;

CREATE PUBLIC SYNONYM ejemplar
FOR PRY2205_USER1.ejemplar;

CREATE PUBLIC SYNONYM prestamo
FOR PRY2205_USER1.prestamo;

-- como user_2

CREATE SEQUENCE SEQ_CONTROL_STOCK
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE TABLE CONTROL_STOCK_LIBROS (
    ID_CONTROL   NUMBER PRIMARY KEY,
    ID_LIBRO           NUMBER NOT NULL,
    NOMBRE_LIBRO       VARCHAR2(200),
    TOTAL_EJEMPLARES        NUMBER,
    EN_PRESTAMO   NUMBER,
    DISPONIBLES NUMBER,
    PORCENTAJE_PRESTAMO NUMBER(5,2),
    STOCK_CRITICO CHAR(1)
);

INSERT INTO CONTROL_STOCK_LIBROS (
    ID_CONTROL, ID_LIBRO, NOMBRE_LIBRO, TOTAL_EJEMPLARES,
    EN_PRESTAMO, DISPONIBLES, PORCENTAJE_PRESTAMO, STOCK_CRITICO
)
SELECT
    seq_control_stock.NEXTVAL,
    id_libro, nombre_libro, total_ejemplares,
    en_prestamo, disponibles, porcentaje_prestamo, stock_critico
FROM (
    SELECT
        l.libroid AS id_libro,
        l.nombre_libro,
        NVL(s.total_ejemplares,0) AS total_ejemplares,
        NVL(p.en_prestamo,0) AS en_prestamo,
        NVL(s.total_ejemplares,0)-NVL(p.en_prestamo,0) AS disponibles,
        CASE
            WHEN NVL(s.total_ejemplares,0)=0 THEN 0
            ELSE ROUND((NVL(p.en_prestamo,0)*100)/NVL(s.total_ejemplares,0),2)
        END AS porcentaje_prestamo,
        CASE
            WHEN NVL(s.total_ejemplares,0)-NVL(p.en_prestamo,0)>2 THEN 'S'
            ELSE 'N'
        END AS stock_critico
    FROM libro l
    LEFT JOIN (
        SELECT libroid, COUNT(*) AS total_ejemplares
        FROM ejemplar
        GROUP BY libroid
    ) s ON l.libroid = s.libroid
    LEFT JOIN (
        SELECT libroid, COUNT(DISTINCT prestamoid) AS en_prestamo
        FROM prestamo
        WHERE empleadoid IN (150,180,190)
          AND fecha_inicio >= ADD_MONTHS(TRUNC(SYSDATE,'MM'), -24)
          AND fecha_inicio <  ADD_MONTHS(TRUNC(SYSDATE,'MM'), -23)
        GROUP BY libroid
    ) p ON l.libroid = p.libroid
    ORDER BY l.libroid;
);

-- caso 3

-- con user_1
CREATE OR REPLACE VIEW VW_DETALLE_MULTAS 
SELECT
    p.prestamoid AS ID_PRESTAMO,
    a.nombre || ' ' || a.apaterno AS NOMBRE_ALUMNO,
    c.descripcion AS NOMBRE_CARRERA,
    p.libroid AS ID_LIBRO,
     TO_CHAR(l.precio, '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) AS VALOR_LIBRO,
    TO_CHAR(p.fecha_termino, 'DD/MM/YYYY') AS FECHA_TERMINO,
    TO_CHAR(p.fecha_entrega, 'DD/MM/YYYY') AS FECHA_ENTREGA,
    GREATEST(TRUNC(p.fecha_entrega - p.fecha_termino), 0) AS DIAS_ATRASO,
    TO_CHAR(GREATEST(TRUNC(p.fecha_entrega - p.fecha_termino), 0) * (l.precio * 0.03), 
        '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) AS VALOR_MULTA,
    TO_CHAR(NVL(r.porc_rebaja_multa,0)/100, '0D99', 'NLS_NUMERIC_CHARACTERS='',.''') AS PORCENTAJE_DESCUENTO,
    TO_CHAR(
        GREATEST(TRUNC(p.fecha_entrega - p.fecha_termino), 0) * (l.precio * 0.03) *
        (1 - NVL(r.porc_rebaja_multa,0)/100),
        '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.'''
    ) AS VALOR_REBAJADO
FROM
    alumno a
    JOIN prestamo p ON p.alumnoid = a.alumnoid
    JOIN libro l ON l.libroid = p.libroid
    JOIN carrera c ON c.carreraid = a.carreraid
    LEFT JOIN rebaja_multa r ON r.carreraid = c.carreraid
WHERE
    p.fecha_termino < p.fecha_entrega AND
    EXTRACT(YEAR FROM p.fecha_termino) = EXTRACT(YEAR FROM SYSDATE) - 2
ORDER BY 
    p.fecha_entrega DESC;

-- caso 3.2
-- con user_1

CREATE INDEX idx_prestamo_fecha_termino ON prestamo(fecha_termino);
CREATE INDEX idx_prestamo_alumno_fecha ON prestamo(alumnoid, fecha_termino);
CREATE INDEX idx_prestamo_libro ON prestamo(libroid);
CREATE INDEX idx_prestamo_fecha_entrega_desc ON prestamo(fecha_entrega DESC);