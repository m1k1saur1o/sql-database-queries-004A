-- caso 1

SELECT
    CASE
        WHEN LENGTH(c.numrun) = 7 THEN TO_CHAR(c.numrun, '9G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || c.dvrun
        WHEN LENGTH(c.numrun) = 8 THEN TO_CHAR(c.numrun, '99G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || c.dvrun
        WHEN LENGTH(c.numrun) = 9 THEN TO_CHAR(c.numrun, '999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || c.dvrun
    END AS "RUT Cliente",
    INITCAP(c.pnombre || ' ' || c.appaterno) AS "Nombre Cliente",
    UPPER(po.nombre_prof_ofic) AS "Profesión Cliente",
    TO_CHAR(c.fecha_inscripcion, 'DD-MM-YYYY') AS "Fecha de inscripción",
    c.direccion AS "Dirección Cliente"
FROM cliente c
LEFT JOIN profesion_oficio po 
    ON c.cod_prof_ofic = po.cod_prof_ofic
WHERE (
        UPPER(po.nombre_prof_ofic) = 'CONTADOR'
        OR UPPER(po.nombre_prof_ofic) = 'VENDEDOR'
    )
    AND TO_CHAR(c.fecha_inscripcion, 'YYYY') >
        (SELECT ROUND(AVG(TO_CHAR(fecha_inscripcion, 'YYYY')))
         FROM cliente)
ORDER BY "RUT Cliente" ASC

-- caso 2

CREATE TABLE CLIENTES_CUPOS_COMPRA AS
SELECT  
    c.numrun || '-' || c.dvrun AS "RUT_CLIENTE",
    FLOOR(MONTHS_BETWEEN(SYSDATE, c.fecha_nacimiento) / 12) AS EDAD,
    TO_CHAR(tcc.cupo_disp_compra, '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) AS "CUPO_DISPONIBLE_COMPRA",
    UPPER(tc.nombre_tipo_cliente) AS "TIPO_CLIENTE"
FROM cliente c
LEFT JOIN tipo_cliente tc 
    ON c.cod_tipo_cliente = tc.cod_tipo_cliente
LEFT JOIN tarjeta_cliente tcc 
    ON c.numrun = tcc.numrun
WHERE tcc.cupo_disp_compra >= (
        SELECT MAX(cupo_disp_compra)
        FROM tarjeta_cliente
        WHERE EXTRACT(YEAR FROM fecha_solic_tarjeta) = EXTRACT(YEAR FROM SYSDATE) - 1
)
ORDER BY EDAD ASC;